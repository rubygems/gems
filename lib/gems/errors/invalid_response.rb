require_relative "error"

module Gems
  # Error raised when a successful response cannot be read: its body is not JSON, such as the page of a proxy or
  # captive portal, its JSON lacks a field the library reads or has one of another type, or a timestamp in it cannot
  # be parsed
  # @api public
  class InvalidResponse < Error
    # The text that could not be read
    # @api public
    # @return [String] the response body, or the value of the attribute, that could not be read
    # @example Get the body
    #   error.body
    attr_reader :body

    # Initialize a new InvalidResponse
    #
    # @api public
    # @param body [String] the response body, or the value of the attribute, that could not be read
    # @param message [String] the error message
    # @return [InvalidResponse] a new instance
    # @example Create an invalid response error
    #   Gems::InvalidResponse.new(body: "<html>")
    # @example Create an invalid response error for a missing field
    #   Gems::InvalidResponse.new(body: "{}", message: "The response body has no version")
    def initialize(body:, message: "The response body is not JSON")
      super(message)
      @body = body
    end
  end
end
