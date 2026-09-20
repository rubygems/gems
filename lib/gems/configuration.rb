require "rubygems"
require_relative "connection"
require_relative "identifiers"
require_relative "redirect_handler"
require_relative "request_builder"
require_relative "retry_handler"
require_relative "url_validation"

module Gems
  # Global configuration for {Gems::Client} instances
  # @api public
  module Configuration
    include Identifiers
    include URLValidation

    # The API endpoint used when the RUBYGEMS_HOST environment variable is not set
    DEFAULT_HOST = "https://rubygems.org".freeze

    # The default 'User-Agent' HTTP header
    DEFAULT_USER_AGENT = RequestBuilder::DEFAULT_USER_AGENT

    # The host used for API requests
    # @api public
    # @return [String] the host, including scheme
    # @example Get the host
    #   Gems.host
    attr_reader :host

    # The OIDC ID token used for trusted publishing
    # @api public
    # @return [String, nil] the OIDC ID token
    # @example Get or set the ID token
    #   Gems.id_token = ENV.fetch("ID_TOKEN")
    attr_accessor :id_token

    # Set the host used for API requests
    #
    # The host is checked here rather than when a request is made with it, as {Client#host=} checks the host of a
    # client, so that the error names the assignment that was wrong.
    #
    # @api public
    # @param host [String] the host, including scheme
    # @return [void]
    # @raise [ArgumentError] if the host is not an HTTP or HTTPS URL, in which case the host is left as it was
    # @example Set the host
    #   Gems.host = "https://gems.example.com"
    def host=(host)
      @host = validate_host(host)
    end

    # Set the API key used for authentication
    #
    # @api public
    # @param key [String, APIKey, nil] the API key, or an API key object
    # @return [void]
    # @example Set the API key
    #   Gems.key = "rubygems_701243f217cdf23b1370c7b66b65ca97"
    # @example Set the API key from a newly created API key
    #   Gems.key = Gems.create_api_key("ci-push", push_rubygem: true)
    def key=(key)
      @key = key_of(key)
    end

    # The one-time passcode used for multi-factor authentication
    # @api public
    # @return [String, nil] the one-time passcode
    # @example Get or set the one-time passcode
    #   Gems.otp = "123456"
    attr_accessor :otp

    # The password used for HTTP basic authentication
    # @api public
    # @return [String, nil] the password
    # @example Get or set the password
    #   Gems.password = "schwwwwing"
    attr_accessor :password

    # The 'User-Agent' HTTP header sent with requests
    # @api public
    # @return [String] the user agent
    # @example Get or set the user agent
    #   Gems.user_agent = "Custom User Agent"
    attr_accessor :user_agent

    # The username used for HTTP basic authentication
    # @api public
    # @return [String, nil] the username
    # @example Get or set the username
    #   Gems.username = "nick@gemcutter.org"
    attr_accessor :username

    # The timeout for opening connections in seconds
    # @api public
    # @return [Integer] the timeout for opening connections in seconds
    # @example Get or set the open timeout
    #   Gems.open_timeout = 30
    attr_accessor :open_timeout

    # The timeout for reading responses in seconds
    # @api public
    # @return [Integer] the timeout for reading responses in seconds
    # @example Get or set the read timeout
    #   Gems.read_timeout = 30
    attr_accessor :read_timeout

    # The timeout for writing requests in seconds
    # @api public
    # @return [Integer] the timeout for writing requests in seconds
    # @example Get or set the write timeout
    #   Gems.write_timeout = 30
    attr_accessor :write_timeout

    # The seconds an idle connection is kept open for another request
    #
    # Zero closes every connection when its request is done.
    #
    # @api public
    # @return [Integer] the seconds an idle connection is kept open
    # @example Get or set the keep-alive timeout
    #   Gems.keep_alive_timeout = 0
    attr_accessor :keep_alive_timeout

    # The IO object for debug output
    # @api public
    # @return [IO, nil] the IO object for debug output
    # @example Get or set the debug output
    #   Gems.debug_output = $stderr
    attr_accessor :debug_output

    # The proxy URL for requests
    #
    # When nil, proxies are read from the http_proxy, https_proxy, and no_proxy environment variables.
    #
    # @api public
    # @return [String, nil] the proxy URL for requests
    # @example Get the proxy URL
    #   Gems.proxy_url
    attr_reader :proxy_url

    # Set the proxy URL for requests
    #
    # The proxy URL is checked here rather than when a request is made with it, as {Connection#proxy_url=} checks
    # the proxy URL of a connection, so that the error names the assignment that was wrong.
    #
    # @api public
    # @param proxy_url [String, nil] the proxy URL, or nil to read proxies from the environment
    # @return [void]
    # @raise [ArgumentError] if the proxy URL is invalid, in which case the proxy is left as it was; the message
    #   leaves out its user and password
    # @example Set the proxy URL
    #   Gems.proxy_url = "http://proxy.example.com:8080"
    def proxy_url=(proxy_url)
      parse_proxy_uri(proxy_url) unless proxy_url.nil?
      @proxy_url = proxy_url
    end

    # The maximum number of redirects to follow
    # @api public
    # @return [Integer] the maximum number of redirects to follow
    # @example Get or set the maximum redirects
    #   Gems.max_redirects = 5
    attr_accessor :max_redirects

    # The number of times a rate-limited request is sent again
    #
    # Zero, the default, raises {TooManyRequests} or {ServiceUnavailable} rather than waiting.
    #
    # @api public
    # @return [Integer] the number of times a rate-limited request is sent again
    # @example Get or set the maximum retries
    #   Gems.max_retries = 3
    attr_accessor :max_retries

    # The longest a request waits before it is sent again, in seconds
    #
    # A response asking to wait longer than this raises rather than being waited for.
    #
    # @api public
    # @return [Integer] the longest a request waits before it is sent again, in seconds
    # @example Get or set the maximum retry delay
    #   Gems.max_retry_delay = 30
    attr_accessor :max_retry_delay

    # Reset the extending module to the default configuration
    #
    # @api private
    # @param base [Module] the module being extended
    # @return [void]
    def self.extended(base)
      base.reset
    end

    # The API key used for authentication
    #
    # Falls back to {#default_key} until a key is assigned. Assigning nil
    # disables this API-key fallback. Basic authentication and trusted
    # publishing remain available when their credentials are configured.
    #
    # @api public
    # @return [String, nil] the API key
    # @example Get the API key
    #   Gems.key
    def key
      if key_configured?
        @key
      else
        default_key
      end
    end

    # The host `gem push` would use
    #
    # This is the `RUBYGEMS_HOST` environment variable, else RubyGems.org. The environment is read when this method
    # is called, as it is for {#default_key}, rather than when the library is required.
    #
    # @api public
    # @return [String] the host, including scheme
    # @example Get the default host
    #   Gems.default_host
    def default_host
      ENV.fetch("RUBYGEMS_HOST", DEFAULT_HOST)
    end

    # The API key `gem push` would use for a host
    #
    # This is the `GEM_HOST_API_KEY` environment variable, else the key `gem signin --host` stored for the host in
    # ~/.gem/credentials, else the RubyGems.org key `gem signin` stored there. The credentials file is only read when
    # this method is called.
    #
    # An empty `GEM_HOST_API_KEY` counts as no key rather than as an empty one, since a continuous integration
    # service sets a variable to the empty string when the secret it was given is not set, and an empty
    # `Authorization` header answers with a puzzling 401 where a request without one answers with the error the
    # endpoint has for an unauthenticated request.
    #
    # When the credentials file does not have the permissions RubyGems requires, RubyGems reports the problem on
    # standard error and would exit the process; this method returns nil instead.
    #
    # @api public
    # @param gem_host [String] the host to resolve the key for, which defaults to {#host}
    # @return [String, nil] the API key, or nil when none is stored or the credentials file cannot be read
    # @example Get the default API key
    #   Gems.default_key
    # @example Get the default API key for another host
    #   Gems.default_key("https://gems.example.com")
    def default_key(gem_host = host)
      env_key = ENV.fetch("GEM_HOST_API_KEY", "")
      return env_key unless env_key.empty?

      ::Gem.configuration.api_keys.fetch(gem_host) { ::Gem.configuration.rubygems_api_key }
    rescue ::Gem::SystemExitException
      nil
    end

    # Whether an API key has been assigned, rather than falling back to {#default_key}
    #
    # @api private
    # @return [Boolean] whether an API key has been assigned
    # @example
    #   Gems.key_configured?
    def key_configured?
      instance_variable_defined?(:@key)
    end

    # Convenience method to allow configuration options to be set in a block
    #
    # @api public
    # @yield [self] the configuration
    # @return [self]
    # @example Configure the API key
    #   Gems.configure do |config|
    #     config.key = "rubygems_701243f217cdf23b1370c7b66b65ca97"
    #   end
    def configure
      yield self
      self
    end

    # Reset all configuration options to defaults
    #
    # The default host is the one `gem push` would use, which is taken as it is rather than checked the way a host
    # assigned to {#host=} is, so that a `RUBYGEMS_HOST` that is not a URL is reported when a client is built with
    # it rather than when the library is required.
    #
    # @api public
    # @return [self]
    # @example Reset the configuration
    #   Gems.reset
    def reset
      @host = default_host
      self.user_agent = DEFAULT_USER_AGENT
      reset_credentials
      reset_connection
      self
    end

    private

    # Clear all credentials
    # @api private
    # @return [void]
    def reset_credentials
      self.id_token = nil
      remove_instance_variable(:@key) if key_configured?
      self.otp = nil
      self.password = nil
      self.username = nil
    end

    # Reset the connection and redirect options to their defaults
    # @api private
    # @return [void]
    def reset_connection
      self.open_timeout = Connection::DEFAULT_OPEN_TIMEOUT
      self.read_timeout = Connection::DEFAULT_READ_TIMEOUT
      self.write_timeout = Connection::DEFAULT_WRITE_TIMEOUT
      self.keep_alive_timeout = Connection::DEFAULT_KEEP_ALIVE_TIMEOUT
      self.debug_output = nil
      self.proxy_url = nil
      self.max_redirects = RedirectHandler::DEFAULT_MAX_REDIRECTS
      self.max_retries = RetryHandler::DEFAULT_MAX_RETRIES
      self.max_retry_delay = RetryHandler::DEFAULT_MAX_RETRY_DELAY
    end
  end
end
