require "rubygems"
require_relative "connection"
require_relative "redirect_handler"
require_relative "version"

module Gems
  # Global configuration for {Gems::Client} instances
  # @api public
  module Configuration
    # The default API endpoint
    DEFAULT_HOST = ENV.fetch("RUBYGEMS_HOST", "https://rubygems.org").freeze

    # The default 'User-Agent' HTTP header
    DEFAULT_USER_AGENT = "Gems #{VERSION}".freeze

    # The host used for API requests
    # @api public
    # @return [String] the host, including scheme
    # @example Get or set the host
    #   Gems.host = "https://gems.example.com"
    attr_accessor :host

    # The OIDC ID token used for trusted publishing
    # @api public
    # @return [String, nil] the OIDC ID token
    # @example Get or set the ID token
    #   Gems.id_token = ENV.fetch("ID_TOKEN")
    attr_accessor :id_token

    # Set the API key used for authentication
    # @api public
    # @param key [String, nil] the API key
    # @return [void]
    # @example Set the API key
    #   Gems.key = "701243f217cdf23b1370c7b66b65ca97"
    attr_writer :key

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
    # @example Get or set the proxy URL
    #   Gems.proxy_url = "http://proxy.example.com:8080"
    attr_accessor :proxy_url

    # The maximum number of redirects to follow
    # @api public
    # @return [Integer] the maximum number of redirects to follow
    # @example Get or set the maximum redirects
    #   Gems.max_redirects = 5
    attr_accessor :max_redirects

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
    # Falls back to {#default_key} when no key has been set.
    #
    # @api public
    # @return [String, nil] the API key
    # @example Get the API key
    #   Gems.key
    def key
      @key || default_key
    end

    # The API key stored in ~/.gem/credentials by `gem signin`
    #
    # The credentials file is only read when this method is called.
    #
    # @api public
    # @return [String, nil] the stored API key
    # @example Get the stored API key
    #   Gems.default_key
    def default_key
      Gem.configuration.rubygems_api_key
    end

    # Convenience method to allow configuration options to be set in a block
    #
    # @api public
    # @yield [self] the configuration
    # @return [self]
    # @example Configure the API key
    #   Gems.configure do |config|
    #     config.key = "701243f217cdf23b1370c7b66b65ca97"
    #   end
    def configure
      yield self
      self
    end

    # Reset all configuration options to defaults
    #
    # @api public
    # @return [self]
    # @example Reset the configuration
    #   Gems.reset
    def reset
      self.host = DEFAULT_HOST
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
      self.key = nil
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
      self.debug_output = nil
      self.proxy_url = nil
      self.max_redirects = RedirectHandler::DEFAULT_MAX_REDIRECTS
    end
  end
end
