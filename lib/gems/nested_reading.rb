# frozen_string_literal: true

require "json"
require_relative "errors/invalid_response"

module Gems
  # Reads the resources a resource carries in its attributes, included in {Resource}
  #
  # @api private
  module NestedReading
    private

    # Build the resources a reader reads, reporting a misread as an invalid response
    #
    # The body of the response is gone by the time a reader runs, so the error carries what was read, serialized as
    # JSON, to diagnose the host with: the attributes of the resource, or the part of them the reader reads when the
    # rest hold a credential.
    #
    # @api private
    # @param read [Object] the attributes, or the part of them the reader reads, to attach to the error
    # @yield to build the resources
    # @return [Object] what the block returns
    # @raise [InvalidResponse] if the block raises `TypeError`, as {Resource.new} and {Resource.list} do for a value of another shape
    def read_nested(read)
      yield
    rescue TypeError => e
      raise InvalidResponse.new(body: JSON.generate(read), message: "The response body is not the expected JSON: #{e}")
    end
  end
end
