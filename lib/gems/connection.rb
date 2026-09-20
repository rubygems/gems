require "net/http"
require "openssl"
require "uri"
require_relative "errors/network_error"

module Gems
  # Manages HTTP connections to the RubyGems API
  # @api public
  class Connection
    # Default timeout for opening connections in seconds
    DEFAULT_OPEN_TIMEOUT = 60 # seconds
    # Default timeout for reading responses in seconds
    DEFAULT_READ_TIMEOUT = 60 # seconds
    # Default timeout for writing requests in seconds
    DEFAULT_WRITE_TIMEOUT = 60 # seconds
    # Network errors that should be wrapped in NetworkError
    NETWORK_ERRORS = [
      IOError,
      Net::HTTPBadResponse,
      Net::OpenTimeout,
      Net::ReadTimeout,
      Net::WriteTimeout,
      OpenSSL::SSL::SSLError,
      SocketError,
      SystemCallError
    ].freeze

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

    # The host of the proxy
    # @api public
    # @return [String, nil] the proxy host, or nil without a proxy URL
    # @example Get the proxy host
    #   connection.proxy_host
    def proxy_host
      proxy_uri&.host
    end

    # The port of the proxy
    # @api public
    # @return [Integer, nil] the proxy port, or nil without a proxy URL
    # @example Get the proxy port
    #   connection.proxy_port
    def proxy_port
      proxy_uri&.port
    end

    # The user of the proxy, decoded from the proxy URL
    # @api public
    # @return [String, nil] the proxy user, or nil without one
    # @example Get the proxy user
    #   connection.proxy_user
    def proxy_user
      decode(proxy_uri&.user)
    end

    # The password of the proxy, decoded from the proxy URL
    # @api public
    # @return [String, nil] the proxy password, or nil without one
    # @example Get the proxy password
    #   connection.proxy_pass
    def proxy_pass
      decode(proxy_uri&.password)
    end

    # Summarize the connection for the console
    #
    # @api public
    # @return [String] the summary, which includes the proxy URL without its user and password
    # @example Inspect a connection
    #   connection.inspect # => #<Gems::Connection proxy_url=nil open_timeout=60 read_timeout=60 write_timeout=60>
    def inspect
      "#<#{self.class} proxy_url=#{redact(proxy_url).inspect} open_timeout=#{open_timeout} " \
        "read_timeout=#{read_timeout} write_timeout=#{write_timeout}>"
    end

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
      self.proxy_url = proxy_url
    end

    # Perform an HTTP request
    #
    # @api public
    # @param request [Net::HTTPRequest] the HTTP request to perform
    # @return [Net::HTTPResponse] the HTTP response
    # @raise [NetworkError] if a network error occurs
    # @example Perform a request
    #   response = connection.perform(request: request)
    def perform(request:)
      http_client = build_http_client(request.uri)
      http_client.request(request)
    rescue *NETWORK_ERRORS => e
      raise NetworkError, "Network error: #{e}"
    end

    # Set the proxy URL for requests
    #
    # @api public
    # @param proxy_url [String, nil] the proxy URL, or nil to read proxies from the environment again
    # @return [void]
    # @raise [ArgumentError] if the proxy URL is invalid, in which case the proxy is left as it was
    # @example Set the proxy URL
    #   connection.proxy_url = "http://proxy.example.com:8080"
    # @example Clear the proxy URL
    #   connection.proxy_url = nil
    def proxy_url=(proxy_url)
      proxy_uri = proxy_url && parse_proxy_uri(proxy_url)
      @proxy_url = proxy_url
      @proxy_uri = proxy_uri
    end

    private

    # Parse and validate a proxy URL
    # @api private
    # @param proxy_url [String] the proxy URL
    # @return [URI::HTTP] the proxy URI
    # @raise [ArgumentError] if the proxy URL is not a valid HTTP or HTTPS URL; the message leaves out its user and
    #   password
    def parse_proxy_uri(proxy_url)
      proxy_uri = URI(proxy_url)
      raise ArgumentError, "Invalid proxy URL: #{redact(proxy_url)}" unless proxy_uri.is_a?(URI::HTTP)

      proxy_uri
    rescue URI::InvalidURIError
      raise ArgumentError, "Invalid proxy URL: #{redact(proxy_url)}"
    end

    # Remove the user and password from a URL
    # @api private
    # @param url [String, nil] the URL
    # @return [String, nil] the URL without its userinfo, or nil for nil
    def redact(url)
      url&.sub(%r{(?<=//)[^/@]*@}, "")
    end

    # Decode a percent-encoded component of a URL
    # @api private
    # @param component [String, nil] the component
    # @return [String, nil] the decoded component, or nil for nil
    def decode(component)
      component && URI.decode_uri_component(component)
    end

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

      proxy_host, proxy_port, proxy_user, proxy_pass = proxy_arguments_for(uri)
      http_client = Net::HTTP.new(host, uri.port, proxy_host, proxy_port, proxy_user, proxy_pass)
      http_client.use_ssl = uri.scheme.eql?("https")
      configure_http_client(http_client)
    end

    # The proxy host, port, user, and password for a URI, with the user and password decoded
    # @api private
    # @param uri [URI::Generic] the URI to connect to
    # @return [Array] the proxy host, port, user, and password, each nil without a proxy
    def proxy_arguments_for(uri)
      proxy = proxy_uri || uri.find_proxy
      [proxy&.host, proxy&.port, decode(proxy&.user), decode(proxy&.password)]
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
