# frozen_string_literal: true

require "net/http"
require_relative "errors/network_error"
require_relative "retry_after"
require_relative "settings"

module Gems
  # Sends a request again when the server, or the network, turns it away
  #
  # A 429 Too Many Requests says a rate limiter turned the request away before it reached the endpoint, so sending it
  # again is safe for any request, even one that is not idempotent, such as pushing a gem: the endpoint never saw the
  # attempt before it. A 503 Service Unavailable says the server turned the request away rather than acting on it,
  # so sending it again is safe for any request that is idempotent, but it can come from a proxy that gave up on an
  # origin still working on the request, so a request that is not idempotent is not sent again for one. A 502 Bad
  # Gateway and a 504 Gateway
  # Timeout say less: they come from a gateway that could not read an answer from the origin behind it, which may
  # have acted on the request before it went quiet, so a request that asks the server to do something, such as
  # yanking a version, is sent again only when it is safe to be answered twice. Sending a yank again after the
  # origin acted on it answers with the 404 of the version the attempt before it yanked, which would be raised in
  # place of the success the caller was owed.
  #
  # Whether a request is one of those is the caller's to say, with the `retry_refused`, `retry_unanswered`, and
  # `retry_lost` arguments of {#handle}: {Client} says whether the method of the request is idempotent and whether
  # it is safe, since a request such as pushing a gem cannot be sent a second time to find out whether the server
  # received the first one, and a caller that knows better, such as the trusted publishing token exchange, says
  # what it knows instead. A 429 is sent again whatever the caller says, since no request reached the endpoint.
  #
  # A request is sent again twice by default, which is enough for the moment of rate limiting or the lost
  # connection that a retry is for, and {#max_retries} of zero turns retrying off, so that a request that was
  # turned away raises {TooManyRequests}, {BadGateway}, {ServiceUnavailable}, {GatewayTimeout}, or {NetworkError}
  # rather than pausing the caller's thread. A response asking to wait longer than {#max_retry_delay} raises
  # whatever {#max_retries} is, so the wait a caller can be held for is theirs to cap.
  #
  # @api private
  class RetryHandler
    include RetryAfter
    include Settings

    # Default number of times a request is sent again
    DEFAULT_MAX_RETRIES = 2
    # Default longest a request waits before it is sent again, in seconds
    DEFAULT_MAX_RETRY_DELAY = 60 # seconds
    # The status that says a rate limiter turned the request away before it reached the endpoint
    THROTTLED_STATUS = 429
    # The status that says the server turned the request away rather than acting on it
    REFUSED_STATUS = 503
    # The statuses that say a gateway read no answer from the origin, which may have acted on the request
    UNANSWERED_STATUSES = [502, 504].freeze
    private_constant :THROTTLED_STATUS, :REFUSED_STATUS, :UNANSWERED_STATUSES

    # @!method max_retries
    #   The number of times a request is sent again
    #   @api private
    #   @return [Integer] the number of times a request is sent again
    #   @example Get the maximum retries
    #     handler.max_retries
    # @!method max_retries=(max_retries)
    #   Set the number of times a request is sent again
    #   @api private
    #   @param max_retries [Integer] the number of times a request is sent again
    #   @return [void]
    #   @raise [ArgumentError] if it is not a whole number of times, in which case the maximum is left as it was
    #   @example Set the maximum retries
    #     handler.max_retries = 3
    count_setting :max_retries

    # @!method max_retry_delay
    #   The longest a request waits before it is sent again, in seconds
    #   @api private
    #   @return [Numeric] the longest a request waits before it is sent again, in seconds
    #   @example Get the maximum retry delay
    #     handler.max_retry_delay
    # @!method max_retry_delay=(max_retry_delay)
    #   Set the longest a request waits before it is sent again, in seconds
    #   @api private
    #   @param max_retry_delay [Numeric] the longest a request waits before it is sent again, in seconds
    #   @return [void]
    #   @raise [ArgumentError] if it is not a number of seconds, in which case the maximum is left as it was
    #   @example Set the maximum retry delay
    #     handler.max_retry_delay = 30
    seconds_setting :max_retry_delay

    # The source of the randomness the backoff is jittered with
    # @api private
    # @return [Random, Class<Random>] the source of randomness
    # @example Get the source of randomness
    #   handler.random
    attr_reader :random

    # Initialize a new RetryHandler
    #
    # @api private
    # @param max_retries [Integer] the number of times a request is sent again
    # @param max_retry_delay [Numeric] the longest a request waits before it is sent again, in seconds
    # @param random [Random, Class<Random>] the source of the randomness the backoff is jittered with, which
    #   answers `rand` with a Float between zero and one
    # @return [RetryHandler] a new instance
    # @example Create a retry handler
    #   handler = Gems::RetryHandler.new(max_retries: 3)
    def initialize(max_retries: DEFAULT_MAX_RETRIES, max_retry_delay: DEFAULT_MAX_RETRY_DELAY, random: Random)
      self.max_retries = max_retries
      self.max_retry_delay = max_retry_delay
      @random = random
    end

    # Send a request until the server and the network stop turning it away
    #
    # The block is called again for each retry, so a request that was redirected is followed again from the start.
    # The wait between attempts is the one the `Retry-After` header of the response asks for, and doubles from one
    # second otherwise, up to {#max_retry_delay}, jittered as {#backoff} describes; that is the wait after a
    # {NetworkError} too, since a request that never reached the server has no response to read a wait from. A
    # response that asks to wait longer than {#max_retry_delay} is returned rather than waited for, so that the
    # caller is told what happened instead of pausing for as long as the server likes, and a {NetworkError} that
    # has no retry left is raised as it was.
    #
    # A request the server turned away, one it may have acted on, and one that is lost to the network are told
    # apart, since they are not equally safe to send again: a 503 says the server refused the request, a 502 or 504
    # says a gateway read no answer from the origin, which may have acted on it, and a request lost to the network
    # may have arrived and been acted on before the answer went missing. The caller says which of the three its
    # request is safe for, so that the trusted publishing token exchange can be sent again when the endpoint turns it
    # away although it is a POST, and not when it is lost. A 429 is sent again for every request, since a rate
    # limiter answered it before it reached the endpoint.
    #
    # The request is not named, since the block builds one of its own each time it is called, so that a body read
    # as a stream is sent from the start (see {Client#perform}).
    #
    # @api private
    # @param retry_refused [Boolean] whether a request the server turned away with a 503 is sent again
    # @param retry_unanswered [Boolean] whether a request the origin may have acted on is sent again
    # @param retry_lost [Boolean] whether a request lost to the network is sent again
    # @yield the response, each time the request is sent
    # @return [Net::HTTPResponse] the last response
    # @raise [NetworkError] if the request is lost to the network and is not sent again
    # @example Send a safe request, which is safe to send again whatever happened to it
    #   handler.handle(retry_refused: true, retry_unanswered: true, retry_lost: true) { connection.perform(request:) }
    # @example Send a request that is safe to send again only when the server turned it away
    #   handler.handle(retry_refused: true, retry_unanswered: false, retry_lost: false) { connection.perform(request:) }
    # @example Send a request that is safe to send again only when a rate limiter turned it away
    #   handler.handle(retry_refused: false, retry_unanswered: false, retry_lost: false) { connection.perform(request:) }
    def handle(retry_refused:, retry_unanswered:, retry_lost:)
      retries = 0
      loop do
        response = attempt(retries:, retry_refused:, retry_unanswered:, retry_lost:) { yield }
        return response if response

        retries += 1
      end
    end

    private

    # Send a request once, waiting afterwards when it is to be sent again
    #
    # @api private
    # @param retries [Integer] the number of times the request has been sent again
    # @param retry_refused [Boolean] whether a request the server turned away with a 503 is sent again
    # @param retry_unanswered [Boolean] whether a request the origin may have acted on is sent again
    # @param retry_lost [Boolean] whether a request lost to the network is sent again
    # @yield the response to the request
    # @return [Net::HTTPResponse, nil] the response, or nil once the wait before sending the request again is over
    # @raise [NetworkError] if the request is lost to the network and is not sent again
    def attempt(retries:, retry_refused:, retry_unanswered:, retry_lost:)
      response = yield
      delay = retry_delay(response:, retries:, refused: retry_refused, unanswered: retry_unanswered)
      delay ? wait(delay) : response
    rescue NetworkError
      delay = network_retry_delay(retries:, allowed: retry_lost)
      raise unless delay

      wait(delay)
    end

    # Wait before a request is sent again
    #
    # Kernel#sleep takes any Numeric, but its signature asks for the narrower interface Integer and Float happen to
    # answer, so the seconds are passed to it unchecked rather than narrowing what {#max_retry_delay} accepts.
    #
    # @api private
    # @param delay [Numeric] the seconds to wait
    # @return [nil] nothing, so that the caller sends the request again
    def wait(delay)
      sleep(delay) # steep:ignore UnresolvedOverloading
      nil
    end

    # The seconds to wait before sending a request again
    #
    # A wait the response asked for is given up on when it is longer than {#max_retry_delay}, where the wait the
    # handler chose for itself is shortened to it, since a backoff that has grown past the cap is the handler
    # asking to wait longer than the caller allowed rather than the server doing so.
    #
    # @api private
    # @param response [Net::HTTPResponse] the response to the request
    # @param retries [Integer] the number of times the request has been sent again
    # @param refused [Boolean] whether a request the server turned away with a 503 is sent again
    # @param unanswered [Boolean] whether a request the origin may have acted on is sent again
    # @return [Numeric, nil] the seconds to wait, or nil when the request is not sent again
    def retry_delay(response:, retries:, refused:, unanswered:)
      return unless retryable?(retry?(response, refused, unanswered), retries)

      retry_after = retry_after_of(response)
      retry_after ? capped(retry_after) : backoff(retries)
    end

    # The seconds to wait before sending a request again after a network error
    # @api private
    # @param retries [Integer] the number of times the request has been sent again
    # @param allowed [Boolean] whether a request lost to the network is sent again
    # @return [Numeric, nil] the seconds to wait, or nil when the request is not sent again
    def network_retry_delay(retries:, allowed:)
      return unless retryable?(allowed, retries)

      backoff(retries)
    end

    # Whether a request has a retry left and is one the caller allows to be sent again
    # @api private
    # @param allowed [Boolean] whether the request is sent again for what happened to it
    # @param retries [Integer] the number of times the request has been sent again
    # @return [Boolean] whether the request is sent again
    def retryable?(allowed, retries)
      retries < max_retries && allowed
    end

    # The seconds a response asked for, unless longer than the caller allowed
    # @api private
    # @param delay [Integer] the seconds the response asked to wait
    # @return [Integer, nil] the seconds to wait, or nil when they are longer than {#max_retry_delay}
    def capped(delay)
      delay unless delay > max_retry_delay
    end

    # Whether a response is one the request is sent again for
    #
    # A 429 says a rate limiter turned the request away before it reached the endpoint, and is sent again whatever
    # the request; a 503 says the server turned the request away rather than acting on it, and is sent again only by
    # the caller that says its request can be sent twice; a 502 or 504 says a gateway read no answer from the
    # origin, which may have acted on it, and is sent again only by the caller that says its request can be answered
    # twice.
    #
    # @api private
    # @param response [Net::HTTPResponse] the response to the request
    # @param refused [Boolean] whether a request the server turned away with a 503 is sent again
    # @param unanswered [Boolean] whether a request the origin may have acted on is sent again
    # @return [Boolean] whether the request is sent again
    def retry?(response, refused, unanswered)
      status = Integer(response.code)
      status.eql?(THROTTLED_STATUS) || (refused && status.eql?(REFUSED_STATUS)) ||
        (unanswered && UNANSWERED_STATUSES.include?(status))
    end

    # The seconds to wait when the response does not ask for a wait of its own
    #
    # The wait doubles with each retry up to {#max_retry_delay}, and is then jittered down by up to half of itself,
    # so that the clients a server turned away at the same moment do not all send their requests again at the same
    # instant and turn the retry into a second wave of the load the server was shedding. A wait the response asked
    # for is not jittered: the server named the moment it is ready for the request, and jittering that wait down
    # would send the request again before then.
    #
    # @api private
    # @param retries [Integer] the number of times the request has been sent again
    # @return [Numeric] the seconds to wait, between half of the doubling wait and all of it
    def backoff(retries)
      delay = [2**retries, max_retry_delay].min
      delay - (random.rand * delay / 2) #: Numeric
    end
  end
end
