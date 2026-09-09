require "net/http"
require_relative "gem_error"

module Gems
  # Base class for HTTP errors from the RubyGems API
  # @api public
  class HTTPError < GemError
    # The HTTP response
    # @api public
    # @return [Net::HTTPResponse, nil] the HTTP response, if the error was raised for one
    # @example Get the response
    #   error.response
    attr_reader :response

    # The HTTP status code
    # @api public
    # @return [String, nil] the HTTP status code, if the error was raised for a response
    # @example Get the status code
    #   error.code
    attr_reader :code

    # Initialize a new HTTPError
    #
    # @api public
    # @param message [String, nil] the error message (defaults to the response body or status message)
    # @param response [Net::HTTPResponse, nil] the HTTP response
    # @return [HTTPError] a new instance
    # @example Create an HTTP error from a response
    #   error = Gems::HTTPError.new(response: response)
    # @example Create an HTTP error from a message
    #   error = Gems::NotFound.new("This rubygem could not be found.")
    def initialize(message = nil, response: nil)
      super(message || (response && error_message(response)))
      @response = response
      @code = response&.code
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
