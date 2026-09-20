require_relative "error"

module Gems
  # Error raised when a successful response has a body that is not JSON, such as the page of a proxy or captive portal
  # @api public
  class InvalidResponse < Error
    # The response body
    # @api public
    # @return [String] the body that could not be parsed
    # @example Get the body
    #   error.body
    attr_reader :body

    # Initialize a new InvalidResponse
    #
    # @api public
    # @param body [String] the response body
    # @return [InvalidResponse] a new instance
    # @example Create an invalid response error
    #   Gems::InvalidResponse.new(body: "<html>")
    def initialize(body:)
      super("The response body is not JSON")
      @body = body
    end
  end
end
