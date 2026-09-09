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
    # @option options [Integer] :open_timeout the timeout for opening connections in seconds
    # @option options [Integer] :read_timeout the timeout for reading responses in seconds
    # @option options [Integer] :write_timeout the timeout for writing requests in seconds
    # @option options [IO, nil] :debug_output the IO object for debug output
    # @option options [String, nil] :proxy_url the proxy URL for requests
    # @option options [Integer] :max_redirects the maximum number of redirects to follow
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

    # Summarize the client for the console
    #
    # @api public
    # @return [String] the summary, which includes the host and authenticator but never credentials
    # @example Inspect a client
    #   client.inspect # => #<Gems::Client host="https://rubygems.org" authenticator=#<Gems::ApiKeyAuthenticator>>
    def inspect
      "#<#{self.class} host=#{host.inspect} authenticator=#{authenticator.inspect}>"
    end

    # The timeout for opening connections in seconds
    # @api public
    # @return [Integer] the timeout for opening connections in seconds
    # @example Get the open timeout
    #   client.open_timeout
    def open_timeout
      connection.open_timeout
    end

    # Set the timeout for opening connections in seconds
    #
    # @api public
    # @param open_timeout [Integer] the timeout for opening connections in seconds
    # @return [void]
    # @example Set the open timeout
    #   client.open_timeout = 30
    def open_timeout=(open_timeout)
      connection.open_timeout = open_timeout
    end

    # The timeout for reading responses in seconds
    # @api public
    # @return [Integer] the timeout for reading responses in seconds
    # @example Get the read timeout
    #   client.read_timeout
    def read_timeout
      connection.read_timeout
    end

    # Set the timeout for reading responses in seconds
    #
    # @api public
    # @param read_timeout [Integer] the timeout for reading responses in seconds
    # @return [void]
    # @example Set the read timeout
    #   client.read_timeout = 30
    def read_timeout=(read_timeout)
      connection.read_timeout = read_timeout
    end

    # The timeout for writing requests in seconds
    # @api public
    # @return [Integer] the timeout for writing requests in seconds
    # @example Get the write timeout
    #   client.write_timeout
    def write_timeout
      connection.write_timeout
    end

    # Set the timeout for writing requests in seconds
    #
    # @api public
    # @param write_timeout [Integer] the timeout for writing requests in seconds
    # @return [void]
    # @example Set the write timeout
    #   client.write_timeout = 30
    def write_timeout=(write_timeout)
      connection.write_timeout = write_timeout
    end

    # The IO object for debug output
    # @api public
    # @return [IO, nil] the IO object for debug output
    # @example Get the debug output
    #   client.debug_output
    def debug_output
      connection.debug_output
    end

    # Set the IO object for debug output
    #
    # @api public
    # @param debug_output [IO, nil] the IO object for debug output
    # @return [void]
    # @example Set the debug output
    #   client.debug_output = $stderr
    def debug_output=(debug_output)
      connection.debug_output = debug_output
    end

    # The proxy URL for requests
    # @api public
    # @return [String, nil] the proxy URL for requests
    # @example Get the proxy URL
    #   client.proxy_url
    def proxy_url
      connection.proxy_url
    end

    # Set the proxy URL for requests
    #
    # A nil proxy URL is ignored, leaving proxies to be read from the environment.
    #
    # @api public
    # @param proxy_url [String, nil] the proxy URL for requests
    # @return [void]
    # @example Set the proxy URL
    #   client.proxy_url = "http://proxy.example.com:8080"
    def proxy_url=(proxy_url)
      connection.proxy_url = proxy_url unless proxy_url.nil?
    end

    # The maximum number of redirects to follow
    # @api public
    # @return [Integer] the maximum number of redirects to follow
    # @example Get the maximum redirects
    #   client.max_redirects
    def max_redirects
      redirect_handler.max_redirects
    end

    # Set the maximum number of redirects to follow
    #
    # @api public
    # @param max_redirects [Integer] the maximum number of redirects to follow
    # @return [void]
    # @example Set the maximum redirects
    #   client.max_redirects = 5
    def max_redirects=(max_redirects)
      redirect_handler.max_redirects = max_redirects
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
      request_builder.user_agent = user_agent
    end
  end
end
