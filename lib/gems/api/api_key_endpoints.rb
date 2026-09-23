# frozen_string_literal: true

require_relative "../identifiers"
require_relative "../json_parsing"
require_relative "../api_key"
require_relative "../path_escaping"
require_relative "../trusted_publisher_authenticator"

module Gems
  module API
    # The API key endpoints, including trusted publishing
    # @api public
    module APIKeyEndpoints
      include Identifiers
      include JSONParsing
      include PathEscaping

      # Create an API key using HTTP basic auth
      #
      # The key is only returned once, so store it somewhere safe.
      #
      # The endpoint answers with the key alone, so the name the key was asked for is kept in the result, as the
      # name of a gem is kept in the versions of it that {API::VersionEndpoints#versions} returns. A name the
      # endpoint answers with is left as it is.
      #
      # @api public
      # @authenticated true
      # @param name [String] A name for the key.
      # @param scopes [Array<Symbol, String>] The scopes to grant the key, which are among the scopes
      #   {APIKey::SCOPES} names, such as push_rubygem and yank_rubygem; the key is granted these alone.
      # @param expires_at [Time, String, nil] When the key expires, as a Time or an ISO 8601 string.
      # @param rubygem_name [String, Gem, nil] A gem to restrict the key to.
      # @param mfa [Boolean, nil] Whether to require a one-time passcode when the key is used.
      # @return [APIKey] the new API key
      # @raise [ArgumentError] if a scope is not one the API defines
      # @example
      #   Gems.configure do |config|
      #     config.username = "nick@gemcutter.org"
      #     config.password = "schwwwwing"
      #   end
      #   Gems.create_api_key("ci-push", scopes: %i[push_rubygem]).key
      # @example
      #   Gems.create_api_key("ci-push", scopes: %i[push_rubygem], rubygem_name: "gems", expires_at: Time.now + 86_400, mfa: true)
      def create_api_key(name, scopes:, expires_at: nil, rubygem_name: nil, mfa: nil)
        settings = {expires_at: timestamp_of(expires_at), rubygem_name: name_of(rubygem_name), mfa:}.compact
        APIKey.new({"name" => name}.merge(parse_json(post("/api/v1/api_key.json", {**scope_fields(scopes), **settings, name:}))))
      end

      # Update the scopes of an API key using HTTP basic auth
      #
      # The key is granted the scopes it is given alone, and every other scope it had is taken away.
      #
      # The endpoint answers with a message rather than with the key it updated, as the endpoints of {#push},
      # {API::OwnerEndpoints#add_owner}, and the rest of the endpoints that act on something do, so that message is
      # what is returned; {#create_api_key} answers with an {APIKey} because its endpoint answers with the key.
      #
      # @api public
      # @authenticated true
      # @param key [String, APIKey] The API key to update.
      # @param scopes [Array<Symbol, String>] The scopes to grant the key, which are among the scopes
      #   {APIKey::SCOPES} names, such as push_rubygem and yank_rubygem.
      # @return [String] the message the endpoint answers with
      # @raise [ArgumentError] if a scope is not one the API defines
      # @example
      #   Gems.update_api_key "rubygems_701243f217cdf23b1370c7b66b65ca97", scopes: %i[push_rubygem yank_rubygem]
      def update_api_key(key, scopes:)
        patch("/api/v1/api_key", {**scope_fields(scopes), api_key: key_of(key)})
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
        TrustedPublisherAuthenticator.new(id_token:, host:, connection:, request_builder:,
          redirect_handler:, retry_handler:).exchange_token!
      end

      # List the API key roles of the user the API key belongs to
      #
      # @api public
      # @authenticated true
      # @return [Array<APIKeyRole>] the roles
      # @example
      #   Gems.api_key_roles.map(&:name)
      def api_key_roles
        APIKeyRole.list(parse_json(get("/api/v1/oidc/api_key_roles.json")))
      end

      # Return one of the API key roles of the user the API key belongs to
      #
      # @api public
      # @authenticated true
      # @param token [String, APIKeyRole] The token of the role, or a role.
      # @return [APIKeyRole] the role
      # @example
      #   Gems.api_key_role("0123456789abcdef0123456789abcdef").api_key_permissions
      def api_key_role(token)
        APIKeyRole.new(parse_json(get("/api/v1/oidc/api_key_roles/#{escape(token_of(token))}.json")))
      end

      # Exchange an OIDC ID token for an API key by assuming an API key role
      #
      # The role issues a key granted the permissions it was set up with when the ID token satisfies its access
      # policy, whichever gem the key will act on, where {#exchange_trusted_publisher_token} issues one for the gems
      # that trust the workflow the token names. The exchange is sent as that one is: without the credentials of the
      # client, and again when the server turns it away or the network loses it.
      #
      # @api public
      # @authenticated false
      # @param token [String, APIKeyRole] The token of the role, or a role.
      # @param id_token [String] The OIDC ID token.
      # @return [APIKey] the API key the role issued, including its name, scopes, and expiry
      # @example
      #   Gems.assume_api_key_role("0123456789abcdef0123456789abcdef", ENV.fetch("ID_TOKEN")).key
      def assume_api_key_role(token, id_token)
        TrustedPublisherAuthenticator.new(id_token:, host:, connection:, request_builder:, redirect_handler:,
          retry_handler:, exchange_path: "/api/v1/oidc/api_key_roles/#{escape(token_of(token))}/assume_role.json")
          .exchange_token!
      end

      private

      # The form fields that grant an API key the scopes given
      #
      # Every other scope is taken away: every scope the API defines is sent, as granted or not, since the endpoints leave a scope they are not sent
      # as it was. A scope the API does not define would be ignored by the server, leaving a key scoped differently
      # than it was meant to be, so a misspelled scope is reported rather than sent.
      #
      # @api private
      # @param scopes [Array<Symbol, String>] the scopes to grant
      # @return [Hash{Symbol => Boolean}] whether each scope the API defines is granted
      # @raise [ArgumentError] if a scope is not one the API defines
      def scope_fields(scopes)
        granted = [*scopes].map(&:to_sym)
        unknown = granted - APIKey::SCOPES
        unless unknown.empty?
          raise ArgumentError, "Unknown API key scope: #{unknown.join(", ")}. " \
            "The scopes the API defines are: #{APIKey::SCOPES.join(", ")}"
        end

        APIKey::SCOPES.to_h { |scope| [scope, granted.include?(scope)] }
      end
    end
  end
end
