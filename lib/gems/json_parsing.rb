require "json"
require_relative "errors/invalid_response"

module Gems
  # Parses the JSON bodies of API responses, mixed into the API endpoints
  # @api private
  module JSONParsing
    private

    # Errors the block of {#parse_json} raises when the parsed JSON is not the expected shape: a key it fetches is
    # missing, or a value is not of the expected type
    SHAPE_ERRORS = [KeyError, NoMethodError, TypeError].freeze
    private_constant :SHAPE_ERRORS

    # Parse a JSON response body, and read it with the block
    #
    # The block reads the fields the caller needs from the parsed JSON, and an error it raises because the JSON is
    # not the expected shape is reported as an invalid response with the body, rather than as a KeyError, a
    # NoMethodError, or a TypeError.
    #
    # @api private
    # @param body [String] the response body
    # @yield [json] the parsed JSON, to read the fields the caller needs
    # @return [Object] the parsed JSON, or what the block returns
    # @raise [InvalidResponse] if the body is not JSON, or the block finds the JSON is not the expected shape
    def parse_json(body)
      json = JSON.parse(body)
      block_given? ? yield(json) : json
    rescue JSON::ParserError
      raise InvalidResponse.new(body:)
    rescue *SHAPE_ERRORS => e
      raise InvalidResponse.new(body:, message: "The response body is not the expected JSON: #{e}")
    end
  end
end
