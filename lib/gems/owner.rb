# frozen_string_literal: true

require_relative "resource"

module Gems
  # An owner of a gem
  # @api public
  class Owner < Resource
    # The roles the RubyGems API defines for an owner
    #
    # A role the API does not define is refused by {API::OwnerEndpoints#add_owner} and
    # {API::OwnerEndpoints#update_owner} rather than sent, so this is the list a caller building its own role can
    # check against.
    #
    # @api public
    ROLES = %w[maintainer owner].freeze

    inspect_with :handle
    identified_by :id, :handle, :email

    # @!method id
    #   The ID of the owner
    #   @api public
    #   @return [Integer, nil] the ID of the owner
    #   @example
    #     owner.id
    attribute :id

    # @!method handle
    #   The handle of the owner
    #   @api public
    #   @return [String, nil] the handle of the owner
    #   @example
    #     owner.handle
    attribute :handle

    # @!method email
    #   The email address of the owner
    #   @api public
    #   @return [String, nil] the email address of the owner
    #   @example
    #     owner.email
    attribute :email

    # @!method role
    #   The role of the owner, such as "owner" or "maintainer"
    #   @api public
    #   @return [String, nil] the role of the owner
    #   @example
    #     owner.role
    attribute :role
  end
end
