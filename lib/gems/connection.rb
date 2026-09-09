require "forwardable"
require "net/http"
require "openssl"
require "uri"

module Gems
  # Manages HTTP connections to the RubyGems API
  # @api public
  class Connection
    extend Forwardable

    # Default timeout for opening connections in seconds
    DEFAULT_OPEN_TIMEOUT = 60 # seconds
    # Default timeout for reading responses in seconds
    DEFAULT_READ_TIMEOUT = 60 # seconds
    # Default timeout for writing requests in seconds
    DEFAULT_WRITE_TIMEOUT = 60 # seconds

    # The timeout for opening connections in seconds
    # @api public
    # @return [Integer] the timeout for opening connections in seconds
    # @example Get or set the open timeout
    #   connection.open_timeout = 30
    attr_accessor :open_timeout

    # The timeout for reading responses in seconds
    # @api public
    # @return [Integer] the timeout for reading responses in seconds
    # @example Get or set the read timeout
    #   connection.read_timeout = 30
    attr_accessor :read_timeout

    # The timeout for writing requests in seconds
    # @api public
    # @return [Integer] the timeout for writing requests in seconds
    # @example Get or set the write timeout
    #   connection.write_timeout = 30
    attr_accessor :write_timeout

    # The IO object for debug output
    # @api public
    # @return [IO, nil] the IO object for debug output
    # @example Get or set the debug output
    #   connection.debug_output = $stderr
    attr_accessor :debug_output

    # The proxy URL for requests
    # @api public
    # @return [String, nil] the proxy URL for requests
    # @example Get the proxy URL
    #   connection.proxy_url
    attr_reader :proxy_url

    # The parsed proxy URI
    # @api public
    # @return [URI::Generic, nil] the parsed proxy URI
    # @example Get the proxy URI
    #   connection.proxy_uri
    attr_reader :proxy_uri

    def_delegator :proxy_uri, :host, :proxy_host
    def_delegator :proxy_uri, :port, :proxy_port
    def_delegator :proxy_uri, :user, :proxy_user
    def_delegator :proxy_uri, :password, :proxy_pass

    # Initialize a new connection
    #
    # @api public
    # @param open_timeout [Integer] the timeout for opening connections in seconds
    # @param read_timeout [Integer] the timeout for reading responses in seconds
    # @param write_timeout [Integer] the timeout for writing requests in seconds
    # @param debug_output [IO, nil] the IO object for debug output
    # @param proxy_url [String, nil] the proxy URL for requests
    # @return [Connection] a new connection instance
    # @example Create a connection with default settings
    #   connection = Gems::Connection.new
    # @example Create a connection with custom timeouts
    #   connection = Gems::Connection.new(open_timeout: 30, read_timeout: 30)
    def initialize(open_timeout: DEFAULT_OPEN_TIMEOUT, read_timeout: DEFAULT_READ_TIMEOUT,
      write_timeout: DEFAULT_WRITE_TIMEOUT, debug_output: nil, proxy_url: nil)
      @open_timeout = open_timeout
      @read_timeout = read_timeout
      @write_timeout = write_timeout
      @debug_output = debug_output
      self.proxy_url = proxy_url unless proxy_url.nil?
    end

    # Perform an HTTP request
    #
    # @api public
    # @param request [Net::HTTPRequest] the HTTP request to perform
    # @return [Net::HTTPResponse] the HTTP response
    # @example Perform a request
    #   response = connection.perform(request: request)
    def perform(request:)
      http_client = build_http_client(request.uri)
      http_client.request(request)
    end

    # Set the proxy URL for requests
    #
    # @api public
    # @param proxy_url [String] the proxy URL
    # @return [void]
    # @raise [ArgumentError] if the proxy URL is invalid
    # @example Set the proxy URL
    #   connection.proxy_url = "http://proxy.example.com:8080"
    def proxy_url=(proxy_url)
      @proxy_url = proxy_url
      proxy_uri = URI(proxy_url)
      raise ArgumentError, "Invalid proxy URL: #{proxy_uri}" unless proxy_uri.is_a?(URI::HTTP)

      @proxy_uri = proxy_uri
    end

    private

    # Build an HTTP client for the given URI
    #
    # If no proxy URL is configured, the proxy is looked up from the environment
    # (http_proxy, https_proxy, and no_proxy) for the URI's scheme.
    #
    # @api private
    # @param uri [URI::Generic] the URI to connect to
    # @return [Net::HTTP] the HTTP client
    # @raise [ArgumentError] if the URI has no host
    def build_http_client(uri)
      host = uri.host
      raise ArgumentError, "URI has no host: #{uri}" if host.nil?

      proxy = proxy_uri || uri.find_proxy
      http_client = Net::HTTP.new(host, uri.port, proxy&.host, proxy&.port, proxy&.user, proxy&.password)
      http_client.use_ssl = uri.scheme.eql?("https")
      configure_http_client(http_client)
    end

    # Configure an HTTP client with timeout settings
    # @api private
    # @param http_client [Net::HTTP] the HTTP client to configure
    # @return [Net::HTTP] the configured HTTP client
    def configure_http_client(http_client)
      http_client.tap do |c|
        c.open_timeout = open_timeout
        c.read_timeout = read_timeout
        c.write_timeout = write_timeout
        c.set_debug_output(debug_output)
      end
    end
  end
end
