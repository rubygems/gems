require "net/http"
require "time"
require_relative "error"

module Gems
  # Base class for HTTP errors from the RubyGems API
  # @api public
  class HTTPError < Error
    # The HTTP response
    # @api public
    # @return [Net::HTTPResponse] the HTTP response
    # @example Get the response
    #   error.response
    attr_reader :response

    # The HTTP status code
    # @api public
    # @return [Integer] the HTTP status code
    # @example Get the status code
    #   error.code
    attr_reader :code

    # Initialize a new HTTPError
    #
    # The message is the response body, or the status message when the body is empty or an HTML page, such as the
    # error page of a CDN.
    #
    # @api public
    # @param response [Net::HTTPResponse] the HTTP response
    # @return [HTTPError] a new instance
    # @example Create an HTTP error
    #   error = Gems::HTTPError.new(response: response)
    def initialize(response:)
      super(error_message(response))
      @response = response
      @code = Integer(response.code)
    end

    # The seconds to wait before retrying the request
    #
    # RubyGems.org sends a Retry-After header with a 429 Too Many Requests response, and may send one with a 503
    # Service Unavailable response, as a number of seconds or an HTTP date.
    #
    # @api public
    # @return [Integer, nil] the seconds to wait, rounded up and never negative, or nil when the response has no
    #   Retry-After header or one that is neither a number of seconds nor an HTTP date
    # @example Wait before retrying
    #   sleep(error.retry_after || 1)
    def retry_after
      value = response["Retry-After"]
      return if value.nil?

      Integer(value, exception: false) || seconds_until(Time.httpdate(value))
    rescue ArgumentError
      nil
    end

    private

    # The seconds from now until a time, rounded up and never negative
    # @api private
    # @param time [Time] the time
    # @return [Integer] the seconds
    def seconds_until(time)
      [(time - Time.now).ceil, 0].max
    end

    # Get the error message from the response
    # @api private
    # @param response [Net::HTTPResponse] the HTTP response
    # @return [String] the response body, or the status message if the body is empty or an HTML page
    def error_message(response)
      body = response.body.to_s
      return response.message if body.empty? || response.content_type&.casecmp?("text/html")

      body
    end
  end
end
