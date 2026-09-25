# frozen_string_literal: true

require_relative "../identifiers"
require_relative "../json_parsing"
require_relative "../path_escaping"
require_relative "../profile"
require_relative "../webauthn_verification"
require_relative "../webauthn_verification_status"

module Gems
  module API
    # The profile endpoints, which look up users and verify the account with a security key
    # @api public
    module ProfileEndpoints
      include Identifiers
      include JSONParsing
      include PathEscaping

      # Returns basic information about a user
      #
      # @api public
      # @authenticated false
      # @param user [String, Integer, Owner, Profile] The handle or ID of a user, or an owner or profile.
      # @return [Profile]
      # @example
      #   Gems.profile "qrush"
      def profile(user)
        Profile.new(parse_json(get("/api/v1/profiles/#{escape(slug_of(user))}.json")))
      end

      # Returns basic information about your account
      #
      # The profile includes the account's multi-factor authentication level.
      #
      # @api public
      # @authenticated true
      # @return [Profile]
      # @example
      #   Gems.configure do |config|
      #     config.username = "nick@gemcutter.org"
      #     config.password = "schwwwwing"
      #   end
      #   Gems.me.mfa
      def me
        Profile.new(parse_json(get("/api/v1/profile/me.json")))
      end

      # Start a WebAuthn verification of your account
      #
      # An account whose multi-factor authentication is a security key is given a one-time passcode by verifying
      # it: the verification is opened in a browser at its {WebAuthnVerification#path}, where the key is used, and
      # {#webauthn_verification_status} answers with the passcode once it has been, as `gem push` does it.
      #
      # @api public
      # @authenticated true
      # @return [WebAuthnVerification] the verification, with the path to open it at and when it expires
      # @raise [UnprocessableContent] if the account has no security key
      # @example
      #   Gems.webauthn_verification.path
      def webauthn_verification
        WebAuthnVerification.new(parse_json(post("/api/v1/webauthn_verification.json")))
      end

      # Returns the status of a WebAuthn verification of your account
      #
      # The status is "pending" until the verification is done in a browser, and "success" once it has been, with
      # the one-time passcode as the {WebAuthnVerificationStatus#code}; "expired" and "not_found" say the
      # verification cannot be done, with a {WebAuthnVerificationStatus#message} that says why.
      #
      # @api public
      # @authenticated true
      # @param verification [String, WebAuthnVerification] The token of the verification, or the verification.
      # @return [WebAuthnVerificationStatus] the status, with the passcode or a message
      # @example
      #   verification = Gems.webauthn_verification
      #   Gems.webauthn_verification_status(verification).code
      def webauthn_verification_status(verification)
        path = "/api/v1/webauthn_verification/#{escape(webauthn_token_of(verification))}/status.json"
        WebAuthnVerificationStatus.new(parse_json(get(path)))
      end
    end
  end
end
