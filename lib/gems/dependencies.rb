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
    # @api private
    # @param type [String] the dependency type ("runtime" or "development")
    # @return [Array<Dependency>] the dependencies
    def dependencies_of(type)
      Dependency.list(attributes.dig("dependencies", type) || [])
    end
  end
end
