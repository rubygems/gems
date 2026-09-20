require "net/http"
require_relative "errors/network_error"
require_relative "idempotence"
require_relative "retry_after"

module Gems
  # Sends a request again when the server, or the network, turns it away
  #
  # A 429 Too Many Requests, 502 Bad Gateway, 503 Service Unavailable, and 504 Gateway Timeout response all mean the
  # request was turned away rather than acted on, as does a {NetworkError}, so sending it again is safe. Only an
  # idempotent request is retried, since a request such as pushing a gem cannot be sent a second time to find out
  # whether the server received the first one.
  #
  # Retrying is off until {#max_retries} is set, so a request that was turned away raises {TooManyRequests},
  # {BadGateway}, {ServiceUnavailable}, {GatewayTimeout}, or {NetworkError} rather than pausing the caller's thread
  # unless the caller asked for it.
  #
  # @api private
  class RetryHandler
    include Idempotence
    include RetryAfter

    # Default number of times a request is sent again
    DEFAULT_MAX_RETRIES = 0
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
    # @return [Integer] the longest a request waits before it is sent again, in seconds
    # @example Get or set the maximum retry delay
    #   handler.max_retry_delay = 30
    attr_accessor :max_retry_delay

    # Initialize a new RetryHandler
    #
    # @api private
    # @param max_retries [Integer] the number of times a request is sent again
    # @param max_retry_delay [Integer] the longest a request waits before it is sent again, in seconds
    # @return [RetryHandler] a new instance
    # @example Create a retry handler
    #   handler = Gems::RetryHandler.new(max_retries: 3)
    def initialize(max_retries: DEFAULT_MAX_RETRIES, max_retry_delay: DEFAULT_MAX_RETRY_DELAY)
      @max_retries = max_retries
      @max_retry_delay = max_retry_delay
    end

    # Send a request until the server and the network stop turning it away
    #
    # The block is called again for each retry, so a request that was redirected is followed again from the start.
    # The wait between attempts is the one the `Retry-After` header of the response asks for, and doubles from one
    # second otherwise, which is the wait after a {NetworkError} too, since a request that never reached the server
    # has no response to read a wait from. A response that asks to wait longer than {#max_retry_delay} is returned
    # rather than waited for, so that the caller is told what happened instead of pausing for as long as the server
    # likes, and a {NetworkError} that has no retry left is raised as it was.
    #
    # @api private
    # @param request [Net::HTTPRequest] the request being sent
    # @yield the response, each time the request is sent
    # @return [Net::HTTPResponse] the last response
    # @raise [NetworkError] if the request is lost to the network and is not sent again
    # @example Send a request, retrying it when the server asks
    #   handler.handle(request:) { connection.perform(request:) }
    def handle(request:)
      retries = 0
      loop do
        response = attempt(request:, retries:) { yield }
        return response if response

        retries += 1
      end
    end

    private

    # Send a request once, waiting afterwards when it is to be sent again
    #
    # @api private
    # @param request [Net::HTTPRequest] the request being sent
    # @param retries [Integer] the number of times the request has been sent again
    # @yield the response to the request
    # @return [Net::HTTPResponse, nil] the response, or nil once the wait before sending the request again is over
    # @raise [NetworkError] if the request is lost to the network and is not sent again
    def attempt(request:, retries:)
      response = yield
      delay = retry_delay(response:, request:, retries:)
      delay ? wait(delay) : response
    rescue NetworkError
      delay = network_retry_delay(request:, retries:)
      raise unless delay

      wait(delay)
    end

    # Wait before a request is sent again
    # @api private
    # @param delay [Integer] the seconds to wait
    # @return [nil] nothing, so that the caller sends the request again
    def wait(delay)
      sleep(delay)
      nil
    end

    # The seconds to wait before sending a request again
    # @api private
    # @param response [Net::HTTPResponse] the response to the request
    # @param request [Net::HTTPRequest] the request that was sent
    # @param retries [Integer] the number of times the request has been sent again
    # @return [Integer, nil] the seconds to wait, or nil when the request is not sent again
    def retry_delay(response:, request:, retries:)
      return unless retryable?(request, retries) && retry?(response)

      capped(retry_after_of(response) || backoff(retries))
    end

    # The seconds to wait before sending a request again after a network error
    # @api private
    # @param request [Net::HTTPRequest] the request that was sent
    # @param retries [Integer] the number of times the request has been sent again
    # @return [Integer, nil] the seconds to wait, or nil when the request is not sent again
    def network_retry_delay(request:, retries:)
      return unless retryable?(request, retries)

      capped(backoff(retries))
    end

    # Whether a request has a retry left and can be sent a second time
    # @api private
    # @param request [Net::HTTPRequest] the request that was sent
    # @param retries [Integer] the number of times the request has been sent again
    # @return [Boolean] whether the request is sent again
    def retryable?(request, retries)
      retries < max_retries && idempotent?(request)
    end

    # The seconds to wait, unless that is longer than the caller allowed
    # @api private
    # @param delay [Integer] the seconds to wait
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
    # @api private
    # @param retries [Integer] the number of times the request has been sent again
    # @return [Integer] the seconds to wait, which doubles with each retry
    def backoff(retries)
      2**retries #: Integer
    end
  end
end
