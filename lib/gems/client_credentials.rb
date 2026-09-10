require_relative "api_key_authenticator"
require_relative "authenticator"
require_relative "basic_authenticator"
require_relative "identifiers"
require_relative "otp_authenticator"
require_relative "trusted_publisher_authenticator"

module Gems
  # Mixin for client authentication credentials
  # @api private
  module ClientCredentials
    include Identifiers

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
    # @param key [String, ApiKey, nil] the API key, or an API key object
    # @return [void]
    # @example Set the API key
    #   client.key = "701243f217cdf23b1370c7b66b65ca97"
    # @example Set the API key from a newly created API key
    #   client.key = client.create_api_key("ci-push", push_rubygem: true)
    def key=(key)
      @key = key_of(key)
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
    # @param key [String, ApiKey, nil] the API key, or an API key object
    # @param username [String, nil] the username
    # @param password [String, nil] the password
    # @param otp [String, nil] the one-time passcode
    # @param id_token [String, nil] the OIDC ID token
    # @return [void]
    def initialize_credentials(key:, username:, password:, otp:, id_token:)
      @key = key_of(key)
      @username = username
      @password = password
      @otp = otp
      @id_token = id_token
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

      OtpAuthenticator.new(authenticator:, otp:)
    end

    # Build a trusted publisher authenticator if an ID token is available
    # @api private
    # @return [TrustedPublisherAuthenticator, nil] the trusted publisher authenticator or nil
    def trusted_publisher_authenticator
      return unless id_token

      TrustedPublisherAuthenticator.new(id_token:, host: @host, connection: @connection, request_builder: @request_builder)
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
    # @return [ApiKeyAuthenticator, nil] the API key authenticator or nil
    def api_key_authenticator
      return unless key

      ApiKeyAuthenticator.new(key:)
    end
  end
end
