# frozen_string_literal: true

require_relative "api_key_authenticator"
require_relative "authenticator"
require_relative "basic_authenticator"
require_relative "identifiers"
require_relative "otp_authenticator"
require_relative "trusted_publisher_authenticator"
require_relative "url_validation"

module Gems
  # Mixin for client authentication credentials, included in {Client}
  # @api public
  module ClientCredentials
    include Identifiers
    include URLValidation

    # Sentinel for a key that was not given, so that a key given as nil, which sends requests without one, is told
    # apart from no key at all, which falls back to the configured key or the key stored for the host
    UNSET = Object.new.freeze
    private_constant :UNSET

    # The API key
    # @api public
    # @return [String, nil] the API key
    # @example Get the API key
    #   client.key
    attr_reader :key

    # The username for HTTP basic authentication
    # @api public
    # @return [String, nil] the username
    # @example Get the username
    #   client.username
    attr_reader :username

    # The password for HTTP basic authentication
    # @api public
    # @return [String, nil] the password
    # @example Get the password
    #   client.password
    attr_reader :password

    # The one-time passcode for multi-factor authentication
    # @api public
    # @return [String, nil] the one-time passcode
    # @example Get the one-time passcode
    #   client.otp
    attr_reader :otp

    # The OIDC ID token for trusted publishing
    # @api public
    # @return [String, nil] the OIDC ID token
    # @example Get the ID token
    #   client.id_token
    attr_reader :id_token

    # The authenticator for API requests
    # @api public
    # @return [Authenticator] the authenticator instance
    # @example Get the authenticator
    #   client.authenticator
    attr_reader :authenticator

    # Set the API key
    #
    # @api public
    # @param key [String, APIKey, nil] the API key, or an API key object
    # @return [void]
    # @example Set the API key
    #   client.key = "rubygems_701243f217cdf23b1370c7b66b65ca97"
    # @example Set the API key from a newly created API key
    #   client.key = client.create_api_key("ci-push", push_rubygem: true)
    def key=(key)
      @key = key_of(key)
      @key_configured = true
      initialize_authenticator
    end

    # Set the username for HTTP basic authentication
    #
    # @api public
    # @param username [String, nil] the username
    # @return [void]
    # @example Set the username
    #   client.username = "nick@gemcutter.org"
    def username=(username)
      @username = username
      initialize_authenticator
    end

    # Set the password for HTTP basic authentication
    #
    # @api public
    # @param password [String, nil] the password
    # @return [void]
    # @example Set the password
    #   client.password = "schwwwwing"
    def password=(password)
      @password = password
      initialize_authenticator
    end

    # Set the one-time passcode for multi-factor authentication
    #
    # @api public
    # @param otp [String, nil] the one-time passcode
    # @return [void]
    # @example Set the one-time passcode
    #   client.otp = "123456"
    def otp=(otp)
      @otp = otp
      initialize_authenticator
    end

    # Set the OIDC ID token for trusted publishing
    #
    # @api public
    # @param id_token [String, nil] the OIDC ID token
    # @return [void]
    # @example Set the ID token
    #   client.id_token = ENV.fetch("ID_TOKEN")
    def id_token=(id_token)
      @id_token = id_token
      initialize_authenticator
    end

    private

    # Initialize credential instance variables
    # @api private
    # @param key [String, APIKey, nil] the API key, or an API key object
    # @param username [String, nil] the username
    # @param password [String, nil] the password
    # @param otp [String, nil] the one-time passcode
    # @param id_token [String, nil] the OIDC ID token
    # @return [void]
    def initialize_credentials(key:, username:, password:, otp:, id_token:)
      @key_configured = key.equal?(UNSET) ? Gems.key_configured? : true
      @key = key_of(key.equal?(UNSET) ? configured_key : key)
      @username = username
      @password = password
      @otp = otp
      @id_token = id_token
    end

    # Resolve the API key stored for the client's host again
    #
    # Only a key the client fell back to is resolved again: a configured key, like the key of `gem push --key`, is
    # sent wherever the client sends a request, and is left as it is.
    #
    # @api private
    # @return [void]
    def resolve_key_for_host
      @key = Gems.default_key(@host) unless @key_configured
    end

    # The API key to use when none was given to the client
    #
    # The configured key, else the key stored for the client's host, so that a client for another host uses the
    # key kept for it rather than the RubyGems.org key.
    #
    # @api private
    # @return [String, nil] the API key
    def configured_key
      Gems.key_configured? ? Gems.key : Gems.default_key(@host)
    end

    # The authenticator for a request to a host
    #
    # A request to a host other than the client's is authenticated with the API key stored for that host, resolved
    # as `gem push --host` resolves it, so that pushing to another host uses the key kept for it. The credentials
    # the caller gave the client are sent wherever the client sends a request, as the configured credentials of
    # `gem push --key` are; the API key a trusted publishing ID token is exchanged for is not one of them (see
    # {#credentials_configured?}), so a client that authenticates its own host with that key sends another host the
    # API key the caller gave it, when it was given one, rather than the key the token was exchanged for.
    #
    # @api private
    # @param host [String] the host of the request
    # @return [Authenticator] the authenticator for the request
    def authenticator_for(host)
      return authenticator if same_origin?(host, @host) || (credentials_configured? && !trusted_publishing?)

      host_key = @key_configured ? key : Gems.default_key(host)
      otp_authenticator(host_key ? APIKeyAuthenticator.new(key: host_key) : Authenticator.new)
    end

    # Whether the client authenticates its own host by trusted publishing
    #
    # It does so with the API key a trusted publishing ID token is exchanged for, when it has an ID token and no basic authentication, which takes precedence over trusted publishing;
    # an API key the caller gave it does not, since trusted publishing takes precedence over an API key.
    #
    # @api private
    # @return [Boolean] whether the client authenticates its own host by trusted publishing
    def trusted_publishing?
      basic_authenticator.nil? && !id_token.nil?
    end

    # Whether the caller gave the client credentials of its own
    #
    # An API key and basic authentication are the caller's own, and are sent wherever the client sends a request,
    # as the key of `gem push --key` is. A trusted publishing ID token is not: the API key it is exchanged for is
    # issued by the host the exchange was made with, for the audience the token names, so sending that key to
    # another host would hand a host a credential it did not issue, which is what the key stored for a host is
    # resolved per request to avoid. A username without a password, or a password without a username, is not
    # basic authentication either, and authenticates nothing.
    #
    # A request to another host falls back to the API key stored for that host instead, as the request of a client
    # without credentials does; {Client#host=} exchanges the ID token again for the host it points the client at.
    #
    # @api private
    # @return [Boolean] whether the caller gave the client credentials of its own
    def credentials_configured?
      @key_configured || !basic_authenticator.nil?
    end

    # Initialize the appropriate authenticator based on available credentials
    #
    # Basic authentication takes precedence over trusted publishing, which takes
    # precedence over an API key. A one-time passcode wraps whichever is chosen.
    #
    # @api private
    # @return [Authenticator] the initialized authenticator
    def initialize_authenticator
      authenticator = basic_authenticator || trusted_publisher_authenticator || api_key_authenticator || Authenticator.new
      @authenticator = otp_authenticator(authenticator)
    end

    # Wrap an authenticator with a one-time passcode if one is available
    # @api private
    # @param authenticator [Authenticator] the authenticator to wrap
    # @return [Authenticator] the wrapped authenticator, or the original if there is no passcode
    def otp_authenticator(authenticator)
      return authenticator unless otp

      OTPAuthenticator.new(authenticator:, otp:)
    end

    # Build a trusted publisher authenticator if an ID token is available
    #
    # The authenticator built for an ID token is kept and given back while the client has that token and the host it
    # would be exchanged with, so that changing another credential, such as the one-time passcode, does not throw
    # away the API key the token was already exchanged for, which RubyGems.org issues once per token. Another token,
    # or another host, is exchanged by an authenticator of its own.
    #
    # @api private
    # @return [TrustedPublisherAuthenticator, nil] the trusted publisher authenticator or nil
    def trusted_publisher_authenticator
      return unless id_token

      kept = @trusted_publisher_authenticator
      return kept if kept && kept.id_token.eql?(id_token) && kept.host.eql?(@host)

      @trusted_publisher_authenticator = TrustedPublisherAuthenticator.new(id_token:, host: @host,
        connection: @connection, request_builder: @request_builder, redirect_handler: @redirect_handler,
        retry_handler: @retry_handler)
    end

    # Build a basic authenticator if a username and password are available
    # @api private
    # @return [BasicAuthenticator, nil] the basic authenticator or nil
    def basic_authenticator
      return unless username && password

      BasicAuthenticator.new(username:, password:)
    end

    # Build an API key authenticator if a key is available
    # @api private
    # @return [APIKeyAuthenticator, nil] the API key authenticator or nil
    def api_key_authenticator
      return unless key

      APIKeyAuthenticator.new(key:)
    end
  end
end
