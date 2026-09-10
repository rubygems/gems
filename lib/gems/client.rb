require "forwardable"
require "uri"
require_relative "api"
require_relative "client_credentials"
require_relative "configuration"
require_relative "connection"
require_relative "redirect_handler"
require_relative "request_builder"
require_relative "response_parser"

module Gems
  # A client for the RubyGems API
  # @api public
  class Client
    extend Forwardable
    include API
    include ClientCredentials

    # The host for API requests
    # @api public
    # @return [String] the host for API requests, including scheme
    # @example Get the host
    #   client.host
    attr_reader :host

    # The connection used for API requests
    # @api public
    # @return [Connection] the connection
    # @example Get the connection
    #   client.connection.proxy_url
    attr_reader :connection

    # The request builder used for API requests
    # @api public
    # @return [RequestBuilder] the request builder
    # @example Get the request builder
    #   client.request_builder.user_agent
    attr_reader :request_builder

    def_delegators :@connection, :open_timeout, :read_timeout, :write_timeout, :proxy_url, :debug_output
    def_delegators :@connection, :open_timeout=, :read_timeout=, :write_timeout=, :proxy_url=, :debug_output=
    def_delegators :@redirect_handler, :max_redirects
    def_delegators :@redirect_handler, :max_redirects=
    def_delegators :@request_builder, :user_agent
    def_delegators :@request_builder, :user_agent=

    # Initialize a new RubyGems API client
    #
    # Every option defaults to the global configuration (see {Gems.configure}).
    #
    # @api public
    # @param host [String] the host for API requests, including scheme
    # @param key [String, ApiKey, nil] the API key, or an API key object
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
    # @param max_redirects [Integer] the maximum number of redirects to follow
    # @return [Client] a new client instance
    # @example Create a client with an API key
    #   client = Gems::Client.new(key: "701243f217cdf23b1370c7b66b65ca97")
    # @example Create a client with HTTP basic authentication
    #   client = Gems::Client.new(username: "nick@gemcutter.org", password: "schwwwwing")
    # @example Create a client with an API key and a one-time passcode
    #   client = Gems::Client.new(key: "701243f217cdf23b1370c7b66b65ca97", otp: "123456")
    # @example Create a client for trusted publishing
    #   client = Gems::Client.new(id_token: ENV.fetch("ID_TOKEN"))
    def initialize(host: Gems.host, key: Gems.key, username: Gems.username, password: Gems.password,
      otp: Gems.otp, id_token: Gems.id_token,
      user_agent: Gems.user_agent,
      open_timeout: Gems.open_timeout,
      read_timeout: Gems.read_timeout,
      write_timeout: Gems.write_timeout,
      debug_output: Gems.debug_output,
      proxy_url: Gems.proxy_url,
      max_redirects: Gems.max_redirects)
      @host = host
      @connection = Connection.new(open_timeout:, read_timeout:, write_timeout:, debug_output:, proxy_url:)
      @request_builder = RequestBuilder.new(user_agent:)
      initialize_credentials(key:, username:, password:, otp:, id_token:)
      initialize_authenticator
      @redirect_handler = RedirectHandler.new(connection: @connection, request_builder: @request_builder, max_redirects:)
      @response_parser = ResponseParser.new
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

    # Perform a GET request to the RubyGems API
    #
    # @api public
    # @param path [String] the request path
    # @param params [Hash] the query parameters
    # @param host [String, nil] the host for the request (defaults to the client's host)
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @example Get information about a gem
    #   client.get("/api/v1/gems/rails.json")
    def get(path, params = {}, host: nil)
      execute_request(:get, path, params:, host:)
    end

    # Perform a DELETE request to the RubyGems API
    #
    # @api public
    # @param path [String] the request path
    # @param params [Hash] the query parameters
    # @param host [String, nil] the host for the request (defaults to the client's host)
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @example Remove an owner from a gem
    #   client.delete("/api/v1/gems/gems/owners", {email: "josh@technicalpickles.com"})
    def delete(path, params = {}, host: nil)
      execute_request(:delete, path, params:, host:)
    end

    # Perform a POST request to the RubyGems API
    #
    # @api public
    # @param path [String] the request path
    # @param body [Hash, Array, String] the request body (form fields, multipart fields, or raw data)
    # @param content_type [String, nil] the content type for a String body (defaults to application/octet-stream)
    # @param host [String, nil] the host for the request (defaults to the client's host)
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @example Add an owner to a gem
    #   client.post("/api/v1/gems/gems/owners", {email: "josh@technicalpickles.com"})
    def post(path, body = {}, content_type: nil, host: nil)
      execute_request(:post, path, body:, content_type:, host:)
    end

    # Perform a PUT request to the RubyGems API
    #
    # @api public
    # @param path [String] the request path
    # @param body [Hash, Array, String] the request body (form fields, multipart fields, or raw data)
    # @param content_type [String, nil] the content type for a String body (defaults to application/octet-stream)
    # @param host [String, nil] the host for the request (defaults to the client's host)
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @example Unyank a gem
    #   client.put("/api/v1/gems/unyank", {gem_name: "gems", version: "0.0.8"})
    def put(path, body = {}, content_type: nil, host: nil)
      execute_request(:put, path, body:, content_type:, host:)
    end

    # Perform a PATCH request to the RubyGems API
    #
    # @api public
    # @param path [String] the request path
    # @param body [Hash, Array, String] the request body (form fields, multipart fields, or raw data)
    # @param content_type [String, nil] the content type for a String body (defaults to application/octet-stream)
    # @param host [String, nil] the host for the request (defaults to the client's host)
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @example Update the scopes of an API key
    #   client.patch("/api/v1/api_key", {api_key: "701243f217cdf23b1370c7b66b65ca97", yank_rubygem: true})
    def patch(path, body = {}, content_type: nil, host: nil)
      execute_request(:patch, path, body:, content_type:, host:)
    end

    # Execute an HTTP request to the RubyGems API
    # @api private
    # @param http_method [Symbol] the HTTP method
    # @param path [String] the request path
    # @param params [Hash] the query parameters
    # @param body [Hash, Array, String, nil] the request body
    # @param content_type [String, nil] the content type for a String body
    # @param host [String, nil] the host for the request (defaults to the client's host)
    # @return [String] the response body
    def execute_request(http_method, path, host:, params: {}, body: nil, content_type: nil)
      uri = URI.join(host || @host, path)
      request = @request_builder.build(http_method:, uri:, params:, body:, content_type:, authenticator:)
      response = @connection.perform(request:)
      response = @redirect_handler.handle(response:, request:, authenticator:)
      @response_parser.parse(response:)
    end
  end
end
