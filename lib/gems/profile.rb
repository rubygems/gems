require_relative "resource"

module Gems
  # A user profile, as returned by the profile endpoints
  # @api public
  class Profile < Resource
    inspect_with :handle
    identified_by :id, :handle

    # @!method id
    #   The ID of the user
    #   @api public
    #   @return [Integer, nil] the ID of the user
    #   @example
    #     profile.id
    attribute :id

    # @!method handle
    #   The handle of the user
    #   @api public
    #   @return [String, nil] the handle of the user
    #   @example
    #     profile.handle
    attribute :handle

    # @!method email
    #   The email address of the user
    #
    #   Only present when the address is public or the profile is your own.
    #   @api public
    #   @return [String, nil] the email address of the user
    #   @example
    #     profile.email
    attribute :email

    # @!method mfa
    #   The multi-factor authentication level
    #
    #   Only present for your own profile: "disabled", "ui_only", "ui_and_api", or "ui_and_gem_signin".
    #   @api public
    #   @return [String, nil] the multi-factor authentication level
    #   @example
    #     profile.mfa
    attribute :mfa

    # @!method warning
    #   A warning that multi-factor authentication is below the recommended level
    #
    #   Only present for your own profile.
    #   @api public
    #   @return [String, nil] the warning
    #   @example
    #     profile.warning
    attribute :warning
  end
end
