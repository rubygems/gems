require_relative "resource"

module Gems
  # A dependency of a gem version
  # @api public
  class Dependency < Resource
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
