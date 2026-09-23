# frozen_string_literal: true

require_relative "resource"

module Gems
  # An API key role, which a workflow whose OIDC ID token its access policy allows can assume for an API key
  #
  # A role is set up on RubyGems.org, where it is given the permissions the API keys it issues are granted and the
  # policy an ID token must satisfy for one to be issued. {API::APIKeyEndpoints#assume_api_key_role} assumes one by
  # its {#token}.
  #
  # @api public
  class APIKeyRole < Resource
    inspect_with :name, :token
    identified_by :token

    # @!method id
    #   The ID of the role
    #   @api public
    #   @return [Integer, nil] the ID of the role
    #   @example
    #     role.id
    attribute :id

    # @!method name
    #   The name of the role, which the API keys it issues are named after
    #   @api public
    #   @return [String, nil] the name of the role
    #   @example
    #     role.name
    attribute :name

    # @!method token
    #   The token the role is assumed by
    #
    #   It names the role rather than granting it: an ID token the access policy allows is what grants it.
    #
    #   @api public
    #   @return [String, nil] the token of the role
    #   @example
    #     role.token
    attribute :token

    # @!method provider_id
    #   The ID of the OIDC provider whose ID tokens the role accepts
    #   @api public
    #   @return [Integer, nil] the ID of the provider
    #   @example
    #     role.provider_id
    attribute :provider_id, "oidc_provider_id"

    # @!method api_key_permissions
    #   The permissions of the API keys the role issues
    #
    #   The scopes they are granted, how long they are valid for, and the gem they are restricted to, if any.
    #
    #   @api public
    #   @return [Hash{String => Object}, nil] the permissions, such as {"scopes" => ["push_rubygem"]}
    #   @example
    #     role.api_key_permissions["scopes"]
    attribute :api_key_permissions

    # @!method access_policy
    #   The policy an ID token must satisfy for the role to issue an API key
    #   @api public
    #   @return [Hash{String => Object}, nil] the access policy, with the statements it is made of
    #   @example
    #     role.access_policy["statements"]
    attribute :access_policy

    # @!method created_at
    #   When the role was created
    #   @api public
    #   @return [Time, nil] when the role was created
    #   @example
    #     role.created_at
    time_attribute :created_at

    # @!method updated_at
    #   When the role was last updated
    #   @api public
    #   @return [Time, nil] when the role was last updated
    #   @example
    #     role.updated_at
    time_attribute :updated_at
  end
end
