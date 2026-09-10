require "json"
require_relative "../identifiers"
require_relative "../profile"

module Gems
  module API
    # The profile endpoints, which look up users
    # @api public
    module ProfileEndpoints
      include Identifiers

      # Returns basic information about a user
      #
      # @api public
      # @authenticated false
      # @param user [String, Integer, Owner, Profile] The handle or ID of a user, or an owner or profile.
      # @return [Profile]
      # @example
      #   Gems.profile "qrush"
      def profile(user)
        Profile.new(JSON.parse(get("/api/v1/profiles/#{handle_of(user)}.json")))
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
        Profile.new(JSON.parse(get("/api/v1/profile/me.json")))
      end
    end
  end
end
