# frozen_string_literal: true

require "net/http"
require_relative "errors/network_error"
require_relative "idempotence"
require_relative "retry_after"

module Gems
  # Sends a request again when the server, or the network, turns it away
  #
  # A 429 Too Many Requests, 502 Bad Gateway, 503 Service Unavailable, and 504 Gateway Timeout response all mean the
  # request was turned away rather than acted on, as does a {NetworkError}, so sending it again is safe. Only an
  # idempotent request is retried by default, since a request such as pushing a gem cannot be sent a second time to
  # find out whether the server received the first one; a caller that knows better, such as the trusted publishing
  # token exchange, says so with the `retry_refused` and `retry_lost` arguments of {#handle}.
  #
  # A request is sent again twice by default, which is enough for the moment of rate limiting or the lost
  # connection that a retry is for, and {#max_retries} of zero turns retrying off, so that a request that was
  # turned away raises {TooManyRequests}, {BadGateway}, {ServiceUnavailable}, {GatewayTimeout}, or {NetworkError}
  # rather than pausing the caller's thread. A response asking to wait longer than {#max_retry_delay} raises
  # whatever {#max_retries} is, so the wait a caller can be held for is theirs to cap.
  #
  # @api private
  class RetryHandler
    include Idempotence
    include RetryAfter

    # Default number of times a request is sent again
    DEFAULT_MAX_RETRIES = 2
    # Default longest a request waits before it is sent again, in seconds
    DEFAULT_MAX_RETRY_DELAY = 60 # seconds
    # The statuses a request is sent again for
    RETRIED_STATUSES = [429, 502, 503, 504].freeze
    private_constant :RETRIED_STATUSES

    # The number of times a request is sent again
    # @api private
    # @return [Integer] the number of times a request is sent again
    # @example Get or set the maximum retries
    #   handler.max_retries = 3
    attr_accessor :max_retries

    # The longest a request waits before it is sent again, in seconds
    # @api private
    # @return [Numeric] the longest a request waits before it is sent again, in seconds
    # @example Get or set the maximum retry delay
    #   handler.max_retry_delay = 30
    attr_accessor :max_retry_delay

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
      @max_retries = max_retries
      @max_retry_delay = max_retry_delay
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
    # A request that is turned away and one that is lost to the network are told apart, since they are not equally
    # safe to send again: a 429, 502, 503, or 504 says the server refused the request rather than acting on it,
    # where a request lost to the network may have arrived and been acted on before the answer went missing. Both
    # default to whether the request is idempotent, and the caller of a request that is not, such as the trusted
    # publishing token exchange, can say that the refusal is safe to retry while the loss is not.
    #
    # @api private
    # @param request [Net::HTTPRequest] the request being sent
    # @param retry_refused [Boolean] whether a request the server turned away is sent again
    # @param retry_lost [Boolean] whether a request lost to the network is sent again
    # @yield the response, each time the request is sent
    # @return [Net::HTTPResponse] the last response
    # @raise [NetworkError] if the request is lost to the network and is not sent again
    # @example Send a request, retrying it when the server asks
    #   handler.handle(request:) { connection.perform(request:) }
    # @example Send a request that is safe to send again only when the server turns it away
    #   handler.handle(request:, retry_refused: true, retry_lost: false) { connection.perform(request:) }
    def handle(request:, retry_refused: idempotent?(request), retry_lost: idempotent?(request))
      retries = 0
      loop do
        response = attempt(retries:, retry_refused:, retry_lost:) { yield }
        return response if response

        retries += 1
      end
    end

    private

    # Send a request once, waiting afterwards when it is to be sent again
    #
    # @api private
    # @param retries [Integer] the number of times the request has been sent again
    # @param retry_refused [Boolean] whether a request the server turned away is sent again
    # @param retry_lost [Boolean] whether a request lost to the network is sent again
    # @yield the response to the request
    # @return [Net::HTTPResponse, nil] the response, or nil once the wait before sending the request again is over
    # @raise [NetworkError] if the request is lost to the network and is not sent again
    def attempt(retries:, retry_refused:, retry_lost:)
      response = yield
      delay = retry_delay(response:, retries:, allowed: retry_refused)
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
    # @param allowed [Boolean] whether a request the server turned away is sent again
    # @return [Numeric, nil] the seconds to wait, or nil when the request is not sent again
    def retry_delay(response:, retries:, allowed:)
      return unless retryable?(allowed, retries) && retry?(response)

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

    # Whether a response turned the request away rather than acting on it
    # @api private
    # @param response [Net::HTTPResponse] the response to the request
    # @return [Boolean] whether the request is sent again
    def retry?(response)
      RETRIED_STATUSES.include?(Integer(response.code))
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
