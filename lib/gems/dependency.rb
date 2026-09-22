# frozen_string_literal: true

require_relative "resource"

module Gems
  # A dependency of a gem version
  # @api public
  class Dependency < Resource
    # The dependency types the RubyGems API defines
    #
    # A type the API does not define is refused by {API::GemEndpoints#reverse_dependencies} rather than sent, so
    # this is the list a caller building its own `only` argument can check against.
    #
    # @api public
    TYPES = %w[development runtime].freeze

    inspect_with :name, :requirements
    identified_by :name, :requirements

    # @!method name
    #   The name of the dependency
    #   @api public
    #   @return [String, nil] the name of the dependency
    #   @example
    #     dependency.name
    attribute :name

    # @!method requirements
    #   The version requirements
    #   @api public
    #   @return [String, nil] the version requirements
    #   @example
    #     dependency.requirements
    attribute :requirements
  end
end
