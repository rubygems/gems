# frozen_string_literal: true

require "net/http"
require "uri"
require_relative "certificate_options"
require_relative "connection_pool"
require_relative "errors/network_error"
require_relative "redacted_output"
require_relative "settings"
require_relative "url_validation"

module Gems
  # Manages HTTP connections to the RubyGems API
  #
  # The connection of a client is its own, and cannot be given to it or read from it, so this class can change
  # within 3.x as the rest of the internals can. Its settings are options of {Client} and of the {Gems} module,
  # such as `open_timeout` and `proxy_url`, which is where they are configured.
  #
  # @api private
  class Connection
    include CertificateOptions
    include Settings
    include URLValidation

    # Default timeout for opening connections in seconds
    DEFAULT_OPEN_TIMEOUT = 60 # seconds
    # Default timeout for reading responses in seconds
    DEFAULT_READ_TIMEOUT = 60 # seconds
    # Default timeout for writing requests in seconds
    DEFAULT_WRITE_TIMEOUT = 60 # seconds
    # Default seconds an idle connection is kept open for another request
    DEFAULT_KEEP_ALIVE_TIMEOUT = 2 # seconds

    # @!method open_timeout
    #   The timeout for opening connections in seconds
    #   @api private
    #   @return [Numeric] the timeout for opening connections in seconds
    #   @example Get the open timeout
    #     connection.open_timeout
    # @!method open_timeout=(open_timeout)
    #   Set the timeout for opening connections in seconds
    #   @api private
    #   @param open_timeout [Numeric] the timeout for opening connections in seconds
    #   @return [void]
    #   @raise [ArgumentError] if it is not a number of seconds, in which case the timeout is left as it was
    #   @example Set the open timeout
    #     connection.open_timeout = 30
    seconds_setting :open_timeout

    # @!method read_timeout
    #   The timeout for reading responses in seconds
    #   @api private
    #   @return [Numeric] the timeout for reading responses in seconds
    #   @example Get the read timeout
    #     connection.read_timeout
    # @!method read_timeout=(read_timeout)
    #   Set the timeout for reading responses in seconds
    #   @api private
    #   @param read_timeout [Numeric] the timeout for reading responses in seconds
    #   @return [void]
    #   @raise [ArgumentError] if it is not a number of seconds, in which case the timeout is left as it was
    #   @example Set the read timeout
    #     connection.read_timeout = 30
    seconds_setting :read_timeout

    # @!method write_timeout
    #   The timeout for writing requests in seconds
    #   @api private
    #   @return [Numeric] the timeout for writing requests in seconds
    #   @example Get the write timeout
    #     connection.write_timeout
    # @!method write_timeout=(write_timeout)
    #   Set the timeout for writing requests in seconds
    #   @api private
    #   @param write_timeout [Numeric] the timeout for writing requests in seconds
    #   @return [void]
    #   @raise [ArgumentError] if it is not a number of seconds, in which case the timeout is left as it was
    #   @example Set the write timeout
    #     connection.write_timeout = 30
    seconds_setting :write_timeout

    # @!method keep_alive_timeout
    #   The seconds an idle connection is kept open for another request
    #
    #   A request is sent on the connection kept open for its host when one was used within this many seconds, so
    #   that a series of requests does not open a connection each. Zero closes every connection when its request is
    #   done.
    #
    #   @api private
    #   @return [Numeric] the seconds an idle connection is kept open
    #   @example Get the keep-alive timeout
    #     connection.keep_alive_timeout
    # @!method keep_alive_timeout=(keep_alive_timeout)
    #   Set the seconds an idle connection is kept open for another request
    #   @api private
    #   @param keep_alive_timeout [Numeric] the seconds an idle connection is kept open
    #   @return [void]
    #   @raise [ArgumentError] if it is not a number of seconds, in which case the timeout is left as it was
    #   @example Set the keep-alive timeout
    #     connection.keep_alive_timeout = 0
    seconds_setting :keep_alive_timeout

    # The IO object for debug output
    #
    # The credentials requests and responses carry are redacted from what is written to it (see {RedactedOutput}).
    #
    # @api private
    # @return [IO, nil] the IO object for debug output
    # @example Get or set the debug output
    #   connection.debug_output = $stderr
    attr_accessor :debug_output

    # The proxy URL for requests
    # @api private
    # @return [String, nil] the proxy URL for requests
    # @example Get the proxy URL
    #   connection.proxy_url
    attr_reader :proxy_url

    # The parsed proxy URI
    # @api private
    # @return [URI::Generic, nil] the parsed proxy URI
    # @example Get the proxy URI
    #   connection.proxy_uri
    attr_reader :proxy_uri

    # Summarize the connection for the console
    #
    # @api private
    # @return [String] the summary, which includes the proxy URL without its user and password
    # @example Inspect a connection
    #   connection.inspect # => #<Gems::Connection proxy_url=nil open_timeout=60 read_timeout=60 write_timeout=60 keep_alive_timeout=2>
    def inspect
      "#<#{self.class} proxy_url=#{redact(proxy_url).inspect} open_timeout=#{open_timeout} " \
        "read_timeout=#{read_timeout} write_timeout=#{write_timeout} keep_alive_timeout=#{keep_alive_timeout}>"
    end

    # Initialize a new connection
    #
    # @api private
    # @param open_timeout [Numeric] the timeout for opening connections in seconds
    # @param read_timeout [Numeric] the timeout for reading responses in seconds
    # @param write_timeout [Numeric] the timeout for writing requests in seconds
    # @param debug_output [IO, nil] the IO object for debug output
    # @param proxy_url [String, nil] the proxy URL for requests
    # @param keep_alive_timeout [Numeric] the seconds an idle connection is kept open for another request
    # @param ca_file [String, nil] the path of a file of certificates TLS is verified with
    # @param ca_path [String, nil] the path of a directory of certificates TLS is verified with
    # @param cert_store [OpenSSL::X509::Store, nil] the store of certificates TLS is verified with
    # @param client_cert [OpenSSL::X509::Certificate, nil] the certificate presented to a host that asks for one
    # @param client_key [OpenSSL::PKey::PKey, nil] the private key of the client certificate
    # @return [Connection] a new connection instance
    # @raise [ArgumentError] if the proxy URL is invalid, or a certificate path names nothing
    # @example Create a connection with default settings
    #   connection = Gems::Connection.new
    # @example Create a connection with custom timeouts
    #   connection = Gems::Connection.new(open_timeout: 30, read_timeout: 30)
    # @example Create a connection that trusts a certificate of its own
    #   connection = Gems::Connection.new(ca_file: "/etc/ssl/certs/internal.pem")
    def initialize(open_timeout: DEFAULT_OPEN_TIMEOUT, read_timeout: DEFAULT_READ_TIMEOUT,
      write_timeout: DEFAULT_WRITE_TIMEOUT, debug_output: nil, proxy_url: nil,
      keep_alive_timeout: DEFAULT_KEEP_ALIVE_TIMEOUT, ca_file: nil, ca_path: nil, cert_store: nil,
      client_cert: nil, client_key: nil)
      self.open_timeout = open_timeout
      self.read_timeout = read_timeout
      self.write_timeout = write_timeout
      @debug_output = debug_output
      self.keep_alive_timeout = keep_alive_timeout
      @pool = ConnectionPool.new
      self.proxy_url = proxy_url
      initialize_certificates(ca_file:, ca_path:, cert_store:, client_cert:, client_key:)
    end

    # Perform an HTTP request
    #
    # The request is sent on the connection kept open for its host, when there is one it can be sent on, and that
    # connection is kept open for the next request (see {#keep_alive_timeout}).
    #
    # The settings are read once, before the connection is taken, and the connection is kept under them, so that a
    # setting changed while the request is being sent, from another thread, closes the connection when the next
    # request is sent rather than keeping it as though it had been opened with the setting as it is now.
    #
    # @api private
    # @param request [Net::HTTPRequest] the HTTP request to perform
    # @return [Net::HTTPResponse] the HTTP response
    # @raise [NetworkError] if a network error occurs
    # @example Perform a request
    #   response = connection.perform(request: request)
    def perform(request:)
      send_request(request, settings, keep_alive_timeout)
    rescue *NetworkError::WRAPPED => e
      raise NetworkError, "Network error: #{e}"
    end

    # Close the connections kept open for the next request
    #
    # The connections are opened again as they are needed, so a connection that is closed while it is being used is
    # not interrupted, and requests can still be made afterwards.
    #
    # @api private
    # @return [Connection] the connection
    # @example Close the connections a client keeps open
    #   connection.close
    def close
      pool.close
      self
    end

    # Set the proxy URL for requests
    #
    # @api private
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

    # The connections kept open for the next request
    # @api private
    # @return [ConnectionPool] the pool
    attr_reader :pool

    # The settings a connection is opened with
    #
    # A connection kept open must still have them to be reused.
    #
    # @api private
    # @return [Hash{Symbol => Object}] the settings
    def settings
      {open_timeout:, read_timeout:, write_timeout:, keep_alive_timeout:, debug_output:, proxy_url:,
       certificates: certificate_settings}
    end

    # Send a request on a connection opened with the settings given
    #
    # The connection is kept under those settings afterwards, rather than under the settings as they are then.
    #
    # A request sent on a connection with a debug output asks for its response uncompressed, since the debug output
    # is written the body as it was sent, and the credentials of a compressed body could not be redacted from it
    # (see {RedactedOutput}).
    #
    # @api private
    # @param request [Net::HTTPRequest] the HTTP request to send
    # @param opened_with [Hash{Symbol => Object}] the settings a connection must have been opened with to send it on
    # @param kept_for [Numeric] the seconds the connection is kept open afterwards
    # @return [Net::HTTPResponse] the HTTP response
    def send_request(request, opened_with, kept_for)
      request["Accept-Encoding"] = "identity" if opened_with.fetch(:debug_output)
      http_client = pool.checkout(request:, settings: opened_with, keep_alive_timeout: kept_for) { build_http_client(request.uri) }
      response = request_on(http_client, request)
      pool.checkin(request:, http_client:, settings: opened_with, keep_alive_timeout: kept_for)
      response
    end

    # Send a request on a connection, and close the connection if the request raises
    #
    # The connection is closed whatever the request raises, rather than left open with a response half read: a
    # timeout of the caller's own, a Thread#raise, or an interrupt stops a request as surely as the network does.
    #
    # @api private
    # @param http_client [Net::HTTP] the connection
    # @param request [Net::HTTPRequest] the HTTP request to send
    # @return [Net::HTTPResponse] the HTTP response
    def request_on(http_client, request)
      http_client.request(request)
    rescue Exception # rubocop:disable Lint/RescueException
      pool.discard(http_client)
      raise
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
    # (http_proxy, https_proxy, and no_proxy) for the URI's scheme. An https:// proxy is connected to over TLS.
    #
    # @api private
    # @param uri [URI::Generic] the URI to connect to
    # @return [Net::HTTP] the HTTP client
    # @raise [ArgumentError] if the URI has no host
    def build_http_client(uri)
      host = uri.host
      raise ArgumentError, "URI has no host: #{uri}" if host.nil?

      proxy_host, proxy_port, proxy_user, proxy_pass, proxy_use_ssl = proxy_arguments_for(uri)
      http_client = Net::HTTP.new(host, uri.port, proxy_host, proxy_port, proxy_user, proxy_pass, nil, proxy_use_ssl)
      http_client.use_ssl = uri.scheme.eql?("https")
      configure_http_client(http_client)
    end

    # The proxy host, port, user, password, and whether to use TLS for a URI
    #
    # The user and password are decoded from the proxy URL, and an https:// proxy is connected to over TLS.
    #
    # @api private
    # @param uri [URI::Generic] the URI to connect to
    # @return [Array] the proxy host, port, user, password, and whether to use TLS, each nil without a proxy
    def proxy_arguments_for(uri)
      proxy = proxy_uri || uri.find_proxy
      [proxy&.host, proxy&.port, decode(proxy&.user), decode(proxy&.password), proxy&.instance_of?(URI::HTTPS)]
    end

    # Configure an HTTP client with timeout settings
    #
    # The debug output is wrapped, so that the credentials Net::HTTP writes with the headers of a request do not
    # reach the IO.
    #
    # Net::HTTP sends an idempotent request again once on its own when the connection it was sent on fails, which
    # the retries of {RetryHandler} would otherwise come on top of, so a request that timed out reading its response
    # would wait twice as many read timeouts as `max_retries` allows for. It is left to {RetryHandler} alone.
    #
    # @api private
    # @param http_client [Net::HTTP] the HTTP client to configure
    # @return [Net::HTTP] the configured HTTP client
    def configure_http_client(http_client)
      http_client.tap do |c|
        c.open_timeout = open_timeout
        c.read_timeout = read_timeout
        c.write_timeout = write_timeout
        c.keep_alive_timeout = keep_alive_timeout
        c.max_retries = 0
        c.set_debug_output(debug_output && RedactedOutput.new(debug_output))
        configure_certificates(c)
      end
    end
  end
end
