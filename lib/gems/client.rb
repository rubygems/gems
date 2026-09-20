require "forwardable"
require "uri"
require_relative "api"
require_relative "client_credentials"
require_relative "configuration"
require_relative "connection"
require_relative "redirect_handler"
require_relative "request_builder"
require_relative "response_parser"
require_relative "retry_handler"
require_relative "url_validation"

module Gems
  # A client for the RubyGems API
  # @api public
  class Client
    extend Forwardable
    include API
    include ClientCredentials
    include URLValidation

    # The host for API requests
    # @api public
    # @return [String] the host for API requests, including scheme
    # @example Get the host
    #   client.host
    attr_reader :host

    def_delegators :@connection, :open_timeout, :read_timeout, :write_timeout, :proxy_url, :debug_output
    def_delegators :@connection, :open_timeout=, :read_timeout=, :write_timeout=, :proxy_url=, :debug_output=
    def_delegators :@connection, :keep_alive_timeout, :keep_alive_timeout=
    def_delegators :@redirect_handler, :max_redirects
    def_delegators :@redirect_handler, :max_redirects=
    def_delegators :@retry_handler, :max_retries, :max_retry_delay
    def_delegators :@retry_handler, :max_retries=, :max_retry_delay=
    def_delegators :@request_builder, :user_agent
    def_delegators :@request_builder, :user_agent=

    # Initialize a new RubyGems API client
    #
    # Every option defaults to the global configuration (see {Gems.configure}).
    #
    # @api public
    # @param host [String] the host for API requests, including scheme
    # @param key [String, APIKey, nil] the API key, an API key object, or nil to send requests without one
    # @param username [String, nil] the username for HTTP basic authentication
    # @param password [String, nil] the password for HTTP basic authentication
    # @param otp [String, nil] the one-time passcode for multi-factor authentication
    # @param id_token [String, nil] the OIDC ID token for trusted publishing
    # @param user_agent [String] the 'User-Agent' HTTP header sent with requests
    # @param open_timeout [Integer] the timeout for opening connections in seconds
    # @param read_timeout [Integer] the timeout for reading responses in seconds
    # @param write_timeout [Integer] the timeout for writing requests in seconds
    # @param debug_output [IO, nil] the IO object for debug output
    # @param proxy_url [String, nil] the proxy URL for requests
    # @param keep_alive_timeout [Integer] the seconds an idle connection is kept open for another request
    # @param max_redirects [Integer] the maximum number of redirects to follow
    # @param max_retries [Integer] the number of times a rate-limited request is sent again
    # @param max_retry_delay [Integer] the longest a request waits before it is sent again, in seconds
    # @return [Client] a new client instance
    # @example Create a client with an API key
    #   client = Gems::Client.new(key: "rubygems_701243f217cdf23b1370c7b66b65ca97")
    # @example Create a client with HTTP basic authentication
    #   client = Gems::Client.new(username: "nick@gemcutter.org", password: "schwwwwing")
    # @example Create a client with an API key and a one-time passcode
    #   client = Gems::Client.new(key: "rubygems_701243f217cdf23b1370c7b66b65ca97", otp: "123456")
    # @example Create a client for trusted publishing
    #   client = Gems::Client.new(id_token: ENV.fetch("ID_TOKEN"))
    # @raise [ArgumentError] if the host is not an HTTP or HTTPS URL
    def initialize(host: Gems.host, key: UNSET, username: Gems.username, password: Gems.password,
      otp: Gems.otp, id_token: Gems.id_token,
      user_agent: Gems.user_agent,
      open_timeout: Gems.open_timeout,
      read_timeout: Gems.read_timeout,
      write_timeout: Gems.write_timeout,
      debug_output: Gems.debug_output,
      proxy_url: Gems.proxy_url,
      keep_alive_timeout: Gems.keep_alive_timeout,
      max_redirects: Gems.max_redirects,
      max_retries: Gems.max_retries,
      max_retry_delay: Gems.max_retry_delay)
      @host = validate_host(host)
      @connection = Connection.new(open_timeout:, read_timeout:, write_timeout:, debug_output:, proxy_url:,
        keep_alive_timeout:)
      @request_builder = RequestBuilder.new(user_agent:)
      initialize_credentials(key:, username:, password:, otp:, id_token:)
      initialize_authenticator
      @redirect_handler = RedirectHandler.new(connection: @connection, request_builder: @request_builder, max_redirects:)
      @retry_handler = RetryHandler.new(max_retries:, max_retry_delay:)
      @response_parser = ResponseParser.new
    end

    # Set the host for API requests
    #
    # When no credentials were configured for the client, the API key stored for the new host is resolved, so that a
    # client pointed at another host sends the key `gem signin --host` stored for it rather than the key of the host
    # the client was built for. A configured key, basic authentication, and a trusted publishing ID token are left as
    # they are, and are sent wherever the client sends a request.
    #
    # @api public
    # @param host [String] the host for API requests, including scheme
    # @return [void]
    # @raise [ArgumentError] if the host is not an HTTP or HTTPS URL, in which case the host is left as it was
    # @example Set the host
    #   client.host = "https://gems.example.com"
    def host=(host)
      @host = validate_host(host)
      resolve_key_for_host
      initialize_authenticator
    end

    # Summarize the client for the console
    #
    # @api public
    # @return [String] the summary, which includes the host and authenticator but never credentials
    # @example Inspect a client
    #   client.inspect # => #<Gems::Client host="https://rubygems.org" authenticator=#<Gems::APIKeyAuthenticator>>
    def inspect
      "#<#{self.class} host=#{host.inspect} authenticator=#{authenticator.inspect}>"
    end

    # Close the connections the client keeps open for the next request
    #
    # The connections are opened again as they are needed, so requests can still be made afterwards.
    #
    # @api public
    # @return [Client] the client
    # @example Close the connections a client keeps open
    #   client.close
    def close
      @connection.close
      self
    end

    # Perform a GET request to the RubyGems API
    #
    # @api public
    # @param path [String] the request path
    # @param params [Hash] the query parameters
    # @param headers [Hash{String => String}] the headers to send with the request, besides the 'User-Agent' and
    #   the credentials of the client
    # @param host [String, nil] the host for the request (defaults to the client's host)
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @example Get information about a gem
    #   client.get("/api/v1/gems/rails.json")
    # @example Send a header of your own
    #   client.get("/api/v1/gems/rails.json", headers: {"Accept" => "application/json"})
    def get(path, params = {}, headers: {}, host: nil)
      execute_request(:get, path, params:, headers:, host:)
    end

    # Perform a DELETE request to the RubyGems API
    #
    # @api public
    # @param path [String] the request path
    # @param params [Hash] the query parameters
    # @param headers [Hash{String => String}] the headers to send with the request, besides the 'User-Agent' and
    #   the credentials of the client
    # @param host [String, nil] the host for the request (defaults to the client's host)
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @example Remove an owner from a gem
    #   client.delete("/api/v1/gems/gems/owners", {email: "josh@technicalpickles.com"})
    def delete(path, params = {}, headers: {}, host: nil)
      execute_request(:delete, path, params:, headers:, host:)
    end

    # Perform a POST request to the RubyGems API
    #
    # @api public
    # @param path [String] the request path
    # @param body [Hash, Array, String] the request body (form fields, multipart fields, or raw data)
    # @param content_type [String, nil] the content type for a String body (defaults to application/octet-stream)
    # @param headers [Hash{String => String}] the headers to send with the request, besides the 'User-Agent', the
    #   content type, and the credentials of the client
    # @param host [String, nil] the host for the request (defaults to the client's host)
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @example Add an owner to a gem
    #   client.post("/api/v1/gems/gems/owners", {email: "josh@technicalpickles.com"})
    def post(path, body = {}, content_type: nil, headers: {}, host: nil)
      execute_request(:post, path, body:, content_type:, headers:, host:)
    end

    # Perform a PUT request to the RubyGems API
    #
    # @api public
    # @param path [String] the request path
    # @param body [Hash, Array, String] the request body (form fields, multipart fields, or raw data)
    # @param content_type [String, nil] the content type for a String body (defaults to application/octet-stream)
    # @param headers [Hash{String => String}] the headers to send with the request, besides the 'User-Agent', the
    #   content type, and the credentials of the client
    # @param host [String, nil] the host for the request (defaults to the client's host)
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @example Unyank a gem
    #   client.put("/api/v1/gems/unyank", {gem_name: "gems", version: "0.0.8"})
    def put(path, body = {}, content_type: nil, headers: {}, host: nil)
      execute_request(:put, path, body:, content_type:, headers:, host:)
    end

    # Perform a PATCH request to the RubyGems API
    #
    # @api public
    # @param path [String] the request path
    # @param body [Hash, Array, String] the request body (form fields, multipart fields, or raw data)
    # @param content_type [String, nil] the content type for a String body (defaults to application/octet-stream)
    # @param headers [Hash{String => String}] the headers to send with the request, besides the 'User-Agent', the
    #   content type, and the credentials of the client
    # @param host [String, nil] the host for the request (defaults to the client's host)
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @example Update the scopes of an API key
    #   client.patch("/api/v1/api_key", {api_key: "rubygems_701243f217cdf23b1370c7b66b65ca97", yank_rubygem: true})
    def patch(path, body = {}, content_type: nil, headers: {}, host: nil)
      execute_request(:patch, path, body:, content_type:, headers:, host:)
    end

    private

    # The connection used for API requests
    # @api private
    # @return [Connection] the connection
    attr_reader :connection

    # The request builder used for API requests
    # @api private
    # @return [RequestBuilder] the request builder
    attr_reader :request_builder

    # Execute an HTTP request to the RubyGems API
    # @api private
    # @param http_method [Symbol] the HTTP method
    # @param path [String] the request path
    # @param params [Hash] the query parameters
    # @param body [Hash, Array, String, nil] the request body
    # @param content_type [String, nil] the content type for a String body
    # @param headers [Hash{String => String}] the headers to send with the request
    # @param host [String, nil] the host for the request (defaults to the client's host)
    # @return [String] the response body
    def execute_request(http_method, path, host:, headers:, params: {}, body: nil, content_type: nil)
      host = host.nil? ? @host : validate_host(host)
      uri = build_uri(host, path)
      authenticator = authenticator_for(host)
      request = @request_builder.build(http_method:, uri:, params:, body:, content_type:, headers:, authenticator:)
      response = @retry_handler.handle(request:) { perform(request:, authenticator:, body:, content_type:, headers:) }
      @response_parser.parse(response:)
    end

    # Send a request and follow the redirects of its response
    #
    # This is what a retry sends again, so that a request that was redirected is followed again from the start
    # rather than sent straight to where the redirect led the first time.
    #
    # @api private
    # @param request [Net::HTTPRequest] the request to send
    # @param authenticator [Authenticator] the authenticator the request was built with
    # @param body [Hash, Array, String, nil] the body the request was built from
    # @param content_type [String, nil] the content type the request was built with, for a String body
    # @param headers [Hash{String => String}] the headers the request was built with
    # @return [Net::HTTPResponse] the response
    def perform(request:, authenticator:, body:, content_type:, headers:)
      response = @connection.perform(request:)
      @redirect_handler.handle(response:, request:, authenticator:, body:, content_type:, headers:)
    end

    # The authenticator for a request to a host
    #
    # A request to a host other than the client's is authenticated with the API key stored for that host, resolved
    # as `gem push --host` resolves it, so that pushing to another host uses the key kept for it. Credentials
    # configured for the client are sent wherever the client sends a request, as the configured credentials of
    # `gem push --key` are.
    #
    # @api private
    # @param host [String] the host of the request
    # @return [Authenticator] the authenticator for the request
    def authenticator_for(host)
      return authenticator if credentials_configured? || same_origin?(host, @host)

      key = Gems.default_key(host)
      otp_authenticator(key ? APIKeyAuthenticator.new(key:) : Authenticator.new)
    end

    # Whether two hosts share a scheme, host, and port
    # @api private
    # @param host [String] one host
    # @param other [String] the other host
    # @return [Boolean] whether the hosts share an origin
    def same_origin?(host, other)
      origin(host).eql?(origin(other))
    end

    # The origin of a host, with the scheme and host in lowercase
    # @api private
    # @param host [String] the host
    # @return [Array] the scheme, host, and port
    def origin(host)
      uri = URI(host).normalize
      [uri.scheme, uri.host, uri.port]
    end

    # Join a host and a request path, keeping any path prefix on the host
    #
    # @api private
    # @param host [String] the host, optionally carrying a path prefix
    # @param path [String] the request path
    # @return [URI] the request URI
    def build_uri(host, path)
      URI.join("#{host.chomp("/")}/", path.delete_prefix("/"))
    end
  end
end
