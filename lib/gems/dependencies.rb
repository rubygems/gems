# frozen_string_literal: true

require "json"
require_relative "dependency"
require_relative "errors/invalid_response"

module Gems
  # The dependencies a gem or a version carries, included in {Gem} and {Version}
  #
  # Only the endpoints that answer with the dependencies of a version carry them: the gem endpoint, the search and
  # activity endpoints, and the API v2 version endpoint. A resource from an endpoint that answers without them, such
  # as the versions of a gem, carries no dependencies rather than none of its own, and the readers answer with an
  # empty Array either way.
  #
  # @api public
  module Dependencies
    # The runtime dependencies
    #
    # @api public
    # @return [Array<Dependency>] the runtime dependencies
    # @example List the runtime dependencies
    #   gem.runtime_dependencies.map(&:name)
    def runtime_dependencies
      dependencies_of("runtime")
    end

    # The development dependencies
    #
    # @api public
    # @return [Array<Dependency>] the development dependencies
    # @example List the development dependencies
    #   gem.development_dependencies.map(&:name)
    def development_dependencies
      dependencies_of("development")
    end

    private

    # The dependencies of the given type
    #
    # A response whose dependencies are not a JSON object, or whose dependencies of the type are not a list, cannot
    # be read: it raises {InvalidResponse}, which carries the response, rather than the raw `TypeError` or
    # `NoMethodError` of the misread, as a timestamp that cannot be parsed does (see {Resource#parse_time}). A
    # dependency the list carries that is not a JSON object raises it too, since there is nothing to read the
    # attributes of a dependency from (see {Resource#initialize}).
    #
    # @api private
    # @param type [String] the dependency type ("runtime" or "development")
    # @return [Array<Dependency>] the dependencies
    # @raise [InvalidResponse] if the dependencies the response carries are not the shape a dependency is read from
    def dependencies_of(type)
      Dependency.list(Array(attributes.dig("dependencies", type)))
    rescue TypeError => e
      raise InvalidResponse.new(body: JSON.generate(attributes),
        message: "The response body is not the expected JSON: #{e}")
    end
  end
end
