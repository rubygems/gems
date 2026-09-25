# frozen_string_literal: true

require_relative "resource"

module Gems
  # An OIDC ID token an API key role accepted, as RubyGems.org keeps it
  #
  # RubyGems.org keeps the claims and the header of each ID token it exchanged for an API key by assuming a role,
  # but not its signature, so the token cannot be sent again.
  #
  # @api public
  class OIDCIDToken < Resource
    inspect_with :api_key_role_token

    # @!method api_key_role_token
    #   The token of the API key role the ID token was exchanged with
    #   @api public
    #   @return [String, nil] the token of the role
    #   @example
    #     id_token.api_key_role_token
    attribute :api_key_role_token

    # @!method jwt
    #   The claims and the header of the ID token
    #   @api public
    #   @return [Hash{String => Object}, nil] the "claims" and the "header" of the token
    #   @example
    #     id_token.jwt["claims"]["repository"]
    attribute :jwt
  end
end
