# frozen_string_literal: true

require_relative "resource"

module Gems
  # An OIDC provider, whose ID tokens RubyGems.org accepts for trusted publishing and for API key roles
  #
  # An {APIKeyRole} names the provider whose ID tokens it accepts by {APIKeyRole#provider_id}, which is the {#id}
  # of the provider.
  #
  # @api public
  class OIDCProvider < Resource
    inspect_with :id, :issuer
    identified_by :id

    # @!method id
    #   The ID of the provider
    #   @api public
    #   @return [Integer, nil] the ID of the provider
    #   @example
    #     provider.id
    attribute :id

    # @!method issuer
    #   The issuer the ID tokens of the provider name
    #
    #   Such as "https://token.actions.githubusercontent.com" for GitHub Actions.
    #
    #   @api public
    #   @return [String, nil] the issuer
    #   @example
    #     provider.issuer
    attribute :issuer

    # @!method configuration
    #   The OpenID configuration the provider publishes
    #   @api public
    #   @return [Hash{String => Object}, nil] the configuration, such as its "jwks_uri"
    #   @example
    #     provider.configuration["jwks_uri"]
    attribute :configuration

    # @!method jwks
    #   The keys the ID tokens of the provider are signed with, as a JSON Web Key Set
    #   @api public
    #   @return [Hash{String => Object}, nil] the key set, with its "keys"
    #   @example
    #     provider.jwks["keys"]
    attribute :jwks

    # @!method created_at
    #   When the provider was added
    #   @api public
    #   @return [Time, nil] when the provider was added
    #   @example
    #     provider.created_at
    time_attribute :created_at

    # @!method updated_at
    #   When the provider was last updated
    #   @api public
    #   @return [Time, nil] when the provider was last updated
    #   @example
    #     provider.updated_at
    time_attribute :updated_at
  end
end
