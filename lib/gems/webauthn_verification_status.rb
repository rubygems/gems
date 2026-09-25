# frozen_string_literal: true

require_relative "resource"

module Gems
  # The status of a WebAuthn verification, as {API::ProfileEndpoints#webauthn_verification_status} answers with it
  #
  # The status is "pending" until the verification is done in a browser, and "success" once it has been, with the
  # one-time passcode as the {#code}; "expired" and "not_found" say the verification cannot be done, with a
  # {#message} that says why. The passcode is a credential, so it is left out of {#inspect}.
  #
  # @api public
  class WebAuthnVerificationStatus < Resource
    inspect_with :status

    # @!method status
    #   The status of the verification
    #   @api public
    #   @return [String, nil] "pending", "success", "expired", or "not_found"
    #   @example
    #     status.status
    attribute :status

    # @!method code
    #   The one-time passcode the verification gives
    #   @api public
    #   @return [String, nil] the passcode, once the status is "success"
    #   @example
    #     status.code
    attribute :code

    # @!method message
    #   Why the verification is not done
    #   @api public
    #   @return [String, nil] the message, unless the status is "success"
    #   @example
    #     status.message
    attribute :message
  end
end
