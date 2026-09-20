require "json"
require_relative "errors/invalid_response"

module Gems
  # Parses the JSON bodies of API responses, mixed into the API endpoints
  # @api private
  module JSONParsing
    private

    # Parse a JSON response body
    # @api private
    # @param body [String] the response body
    # @return [Object] the parsed JSON
    # @raise [InvalidResponse] if the body is not JSON
    def parse_json(body)
      JSON.parse(body)
    rescue JSON::ParserError
      raise InvalidResponse.new(body:)
    end
  end
end
