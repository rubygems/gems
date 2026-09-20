# frozen_string_literal: true

require_relative "../identifiers"
require_relative "../json_parsing"
require_relative "../api_key"
require_relative "../trusted_publisher_authenticator"

module Gems
  module API
    # The API key endpoints, including trusted publishing
    # @api public
    module APIKeyEndpoints
      include Identifiers
      include JSONParsing

      # The scopes the RubyGems API defines for an API key
      #
      # A scope the API does not define is refused by {#create_api_key} and {#update_api_key} rather than sent, so
      # this is the list a caller building its own scopes can check against.
      #
      # @api public
      API_KEY_SCOPES = %i[
        access_webhooks
        add_owner
        configure_trusted_publishers
        index_rubygems
        push_rubygem
        remove_owner
        show_dashboard
        update_owner
        yank_rubygem
      ].freeze

      # Create an API key using HTTP basic auth
      #
      # The key is only returned once, so store it somewhere safe.
      #
      # @api public
      # @authenticated true
      # @param name [String] A name for the key.
      # @param expires_at [Time, String, nil] When the key expires, as a Time or an ISO 8601 string.
      # @param rubygem_name [String, Gem, nil] A gem to restrict the key to.
      # @param mfa [Boolean, nil] Whether to require a one-time passcode when the key is used.
      # @param scopes [Hash{Symbol => Boolean}] The scopes to enable: push_rubygem, yank_rubygem, index_rubygems,
      #   add_owner, remove_owner, access_webhooks, update_owner, configure_trusted_publishers, and show_dashboard.
      # @return [APIKey] the new API key
      # @example
      #   Gems.configure do |config|
      #     config.username = "nick@gemcutter.org"
      #     config.password = "schwwwwing"
      #   end
      #   Gems.create_api_key("ci-push", push_rubygem: true).key
      # @example
      #   Gems.create_api_key("ci-push", push_rubygem: true, rubygem_name: "gems", expires_at: Time.now + 86_400, mfa: true)
      def create_api_key(name, expires_at: nil, rubygem_name: nil, mfa: nil, **scopes)
        validate_scopes(scopes)
        settings = {expires_at: timestamp_of(expires_at), rubygem_name: name_of(rubygem_name), mfa:}.compact
        APIKey.new(parse_json(post("/api/v1/api_key.json", {**scopes, **settings, name:})))
      end

      # Update the scopes of an API key using HTTP basic auth
      #
      # @api public
      # @authenticated true
      # @param key [String, APIKey] The API key to update.
      # @param scopes [Hash{Symbol => Boolean}] Scopes to enable or disable, such as push_rubygem or yank_rubygem.
      # @return [String]
      # @example
      #   Gems.update_api_key "rubygems_701243f217cdf23b1370c7b66b65ca97", yank_rubygem: true
      def update_api_key(key, **scopes)
        validate_scopes(scopes)
        patch("/api/v1/api_key", {**scopes, api_key: key_of(key)})
      end

      # Exchange an OIDC ID token for an API key via trusted publishing
      #
      # @api public
      # @authenticated false
      # @param id_token [String] The OIDC ID token.
      # @return [APIKey] the exchanged API key, including its name, scopes, and expiry
      # @example
      #   Gems.exchange_trusted_publisher_token(ENV.fetch("ID_TOKEN")).key
      def exchange_trusted_publisher_token(id_token)
        TrustedPublisherAuthenticator.new(id_token:, host:, connection:, request_builder:).exchange_token!
      end

      private

      # Check that every scope is one the RubyGems API defines
      #
      # A scope the API does not define would be ignored by the server, leaving a key scoped differently than it
      # was meant to be, so a misspelled scope is reported rather than sent.
      #
      # @api private
      # @param scopes [Hash{Symbol => Boolean}] the scopes
      # @return [void]
      # @raise [ArgumentError] if a scope is not one the API defines
      def validate_scopes(scopes)
        unknown = scopes.keys - API_KEY_SCOPES
        return if unknown.empty?

        raise ArgumentError, "Unknown API key scope: #{unknown.join(", ")}. " \
          "The scopes the API defines are: #{API_KEY_SCOPES.join(", ")}"
      end
    end
  end
end
