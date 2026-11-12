# frozen_string_literal: true

require_relative "dependency"

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
    # Dependencies that are not a JSON object, dependencies of the type that are not a list, or a dependency that is
    # not a JSON object cannot be read: they raise {InvalidResponse}, which carries the attributes of the resource,
    # rather than the raw `TypeError` or `NoMethodError` of the misread.
    #
    # @api private
    # @param type [String] the dependency type ("runtime" or "development")
    # @return [Array<Dependency>] the dependencies
    # @raise [InvalidResponse] if the dependencies are not the shape a dependency is read from
    def dependencies_of(type)
      read_nested(attributes) do
        dependencies = attributes.dig("dependencies", type)
        dependencies.nil? ? [] : Dependency.list(dependencies)
      end
    end
  end
end
