require "net/http"
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
    # @return [String] the HTTP status code
    # @example Get the status code
    #   error.code
    attr_reader :code

    # Initialize a new HTTPError
    #
    # @api public
    # @param response [Net::HTTPResponse] the HTTP response
    # @return [HTTPError] a new instance
    # @example Create an HTTP error
    #   error = Gems::HTTPError.new(response: response)
    def initialize(response:)
      super(error_message(response))
      @response = response
      @code = response.code
    end

    private

    # Get the error message from the response
    # @api private
    # @param response [Net::HTTPResponse] the HTTP response
    # @return [String] the response body, or the status message if the body is empty
    def error_message(response)
      body = response.body.to_s
      return response.message if body.empty?

      body
    end
  end
end
