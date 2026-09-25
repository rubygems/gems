# frozen_string_literal: true

require_relative "resource"

module Gems
  # A WebAuthn verification, which gives an account that signs in with a security key a one-time passcode
  #
  # The verification is opened in a browser at its {#path}, where the security key is used, and
  # {API::ProfileEndpoints#webauthn_verification_status} answers with the one-time passcode once it has been, as
  # `gem push` asks for it for an account whose multi-factor authentication is a security key. The path is a link
  # for the account alone, so it is left out of {#inspect}.
  #
  # @api public
  class WebAuthnVerification < Resource
    inspect_with :expires_at

    # @!method path
    #   The URL the verification is opened at in a browser
    #   @api public
    #   @return [String, nil] the URL, which ends with the token of the verification
    #   @example
    #     verification.path
    attribute :path

    # @!method expires_at
    #   When the verification expires
    #   @api public
    #   @return [Time, nil] when the verification expires
    #   @example
    #     verification.expires_at
    time_attribute :expires_at, "expiry"

    # The token of the verification, which its status is asked for by
    #
    # @api public
    # @return [String, nil] the token, which is the last segment of the path
    # @example
    #   verification.token
    def token
      path.to_s[%r{[^/]+\z}]
    end
    record_attribute(:token)
  end
end
