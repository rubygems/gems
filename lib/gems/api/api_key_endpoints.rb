require "json"
require_relative "../identifiers"
require_relative "../api_key"
require_relative "../trusted_publisher_authenticator"

module Gems
  module API
    # The API key endpoints, including trusted publishing
    # @api public
    module ApiKeyEndpoints
      include Identifiers

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
      # @return [ApiKey] the new API key
      # @example
      #   Gems.configure do |config|
      #     config.username = "nick@gemcutter.org"
      #     config.password = "schwwwwing"
      #   end
      #   Gems.create_api_key("ci-push", push_rubygem: true).key
      # @example
      #   Gems.create_api_key("ci-push", push_rubygem: true, rubygem_name: "gems", expires_at: Time.now + 86_400, mfa: true)
      def create_api_key(name, expires_at: nil, rubygem_name: nil, mfa: nil, **scopes)
        settings = {expires_at: timestamp_of(expires_at), rubygem_name: name_of(rubygem_name), mfa:}.compact
        ApiKey.new(JSON.parse(post("/api/v1/api_key.json", {**scopes, **settings, name:})))
      end

      # Update the scopes of an API key using HTTP basic auth
      #
      # @api public
      # @authenticated true
      # @param key [String, ApiKey] The API key to update.
      # @param scopes [Hash{Symbol => Boolean}] Scopes to enable or disable, such as push_rubygem or yank_rubygem.
      # @return [String]
      # @example
      #   Gems.update_api_key "701243f217cdf23b1370c7b66b65ca97", yank_rubygem: true
      def update_api_key(key, **scopes)
        patch("/api/v1/api_key", {**scopes, api_key: key_of(key)})
      end

      # Exchange an OIDC ID token for an API key via trusted publishing
      #
      # @api public
      # @authenticated false
      # @param id_token [String] The OIDC ID token.
      # @return [ApiKey] the exchanged API key, including its name, scopes, and expiry
      # @example
      #   Gems.exchange_trusted_publisher_token(ENV.fetch("ID_TOKEN")).key
      def exchange_trusted_publisher_token(id_token)
        TrustedPublisherAuthenticator.new(id_token:, host:, connection:, request_builder:).exchange_token!
      end
    end
  end
end
