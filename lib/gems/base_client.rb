require_relative "client_credentials"
require_relative "configuration"
require_relative "request"

module Gems
  # Base class for clients that interact with the RubyGems API
  #
  # Options default to the global configuration (see {Gems.configure}).
  #
  # @api public
  class BaseClient
    include Request
    include ClientCredentials

    # The host for API requests
    # @api public
    # @return [String] the host for API requests, including scheme
    # @example Get the host
    #   client.host
    attr_reader :host

    # The 'User-Agent' HTTP header sent with requests
    # @api public
    # @return [String] the user agent
    # @example Get the user agent
    #   client.user_agent
    attr_reader :user_agent

    # Initialize a new RubyGems API client
    #
    # @api public
    # @param options [Hash{Symbol => Object}] options overriding the global configuration
    # @option options [String] :host the host for API requests, including scheme
    # @option options [String, nil] :key the API key
    # @option options [String, nil] :username the username for HTTP basic authentication
    # @option options [String, nil] :password the password for HTTP basic authentication
    # @option options [String, nil] :otp the one-time passcode for multi-factor authentication
    # @option options [String, nil] :id_token the OIDC ID token for trusted publishing
    # @option options [String] :user_agent the 'User-Agent' HTTP header sent with requests
    # @return [BaseClient] a new client instance
    # @example Create a client with an API key
    #   client = Gems::Client.new(key: "701243f217cdf23b1370c7b66b65ca97")
    # @example Create a client with HTTP basic authentication
    #   client = Gems::Client.new(username: "nick@gemcutter.org", password: "schwwwwing")
    def initialize(options = {})
      Gems.options.merge(options).slice(*Configuration::VALID_OPTIONS_KEYS).each do |key, value|
        public_send(:"#{key}=", value)
      end
    end

    # Set the host for API requests
    #
    # @api public
    # @param host [String] the host for API requests, including scheme
    # @return [void]
    # @example Set the host
    #   client.host = "https://gems.example.com"
    def host=(host)
      @host = host
      initialize_authenticator
    end

    # Set the 'User-Agent' HTTP header sent with requests
    #
    # @api public
    # @param user_agent [String] the user agent
    # @return [void]
    # @example Set the user agent
    #   client.user_agent = "Custom User Agent"
    def user_agent=(user_agent)
      @user_agent = user_agent
      @request_builder&.user_agent = user_agent
    end
  end
end
