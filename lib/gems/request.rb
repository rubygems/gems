require "uri"
require_relative "connection"
require_relative "redirect_handler"
require_relative "request_builder"
require_relative "response_parser"

module Gems
  # HTTP requests for the RubyGems API, mixed into clients
  #
  # Classes that include this module must provide +host+, +user_agent+, and +authenticator+.
  #
  # @api public
  module Request
    # Content type for form-encoded request bodies
    FORM_URLENCODED = "application/x-www-form-urlencoded".freeze

    # The connection used for requests
    #
    # @api public
    # @return [Connection] the connection
    # @example Get the connection
    #   client.connection.proxy_url
    def connection
      @connection ||= Connection.new
    end

    # The request builder used for requests
    #
    # @api public
    # @return [RequestBuilder] the request builder
    # @example Get the request builder
    #   client.request_builder.user_agent
    def request_builder
      @request_builder ||= RequestBuilder.new(user_agent:)
    end

    # The redirect handler used for requests
    #
    # @api public
    # @return [RedirectHandler] the redirect handler
    # @example Get the redirect handler
    #   client.redirect_handler.max_redirects
    def redirect_handler
      @redirect_handler ||= RedirectHandler.new(connection:, request_builder:)
    end

    # The response parser used for requests
    #
    # @api public
    # @return [ResponseParser] the response parser
    # @example Get the response parser
    #   client.response_parser
    def response_parser
      @response_parser ||= ResponseParser.new
    end

    # Perform a GET request
    #
    # @api public
    # @param path [String] the request path
    # @param data [Hash] the query parameters
    # @param content_type [String] the Content-Type header to send
    # @param request_host [String] the host for the request
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @example Get information about a gem
    #   client.get("/api/v1/gems/rails.json")
    def get(path, data = {}, content_type = FORM_URLENCODED, request_host = host)
      request(:get, path, data, content_type, request_host)
    end

    # Perform a DELETE request
    #
    # @api public
    # @param path [String] the request path
    # @param data [Hash] the query parameters
    # @param content_type [String] the Content-Type header to send
    # @param request_host [String] the host for the request
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @example Remove an owner from a gem
    #   client.delete("/api/v1/gems/gems/owners", email: "josh@technicalpickles.com")
    def delete(path, data = {}, content_type = FORM_URLENCODED, request_host = host)
      request(:delete, path, data, content_type, request_host)
    end

    # Perform a POST request
    #
    # @api public
    # @param path [String] the request path
    # @param data [Hash, Array, String] the request body (form fields, multipart fields, or raw data)
    # @param content_type [String] the content type of the body
    # @param request_host [String] the host for the request
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @example Add an owner to a gem
    #   client.post("/api/v1/gems/gems/owners", email: "josh@technicalpickles.com")
    def post(path, data = {}, content_type = FORM_URLENCODED, request_host = host)
      request(:post, path, data, content_type, request_host)
    end

    # Perform a PUT request
    #
    # @api public
    # @param path [String] the request path
    # @param data [Hash, Array, String] the request body (form fields, multipart fields, or raw data)
    # @param content_type [String] the content type of the body
    # @param request_host [String] the host for the request
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @example Unyank a gem
    #   client.put("/api/v1/gems/unyank", gem_name: "gems", version: "0.0.8")
    def put(path, data = {}, content_type = FORM_URLENCODED, request_host = host)
      request(:put, path, data, content_type, request_host)
    end

    private

    # Perform an HTTP request
    # @api private
    # @param http_method [Symbol] the HTTP method
    # @param path [String] the request path
    # @param data [Hash, Array, String] the query parameters or request body
    # @param content_type [String] the content type of the body
    # @param request_host [String] the host for the request
    # @return [String] the response body
    def request(http_method, path, data, content_type, request_host)
      uri = URI.join(request_host, path)
      request = request_builder.build(http_method:, uri:, params: query_params(http_method, data),
        body: request_body(http_method, data, content_type), content_type:, headers: {"Content-Type" => content_type},
        authenticator:)
      response = redirect_handler.handle(response: connection.perform(request:), request:, authenticator:)
      response_parser.parse(response:)
    end

    # The query parameters for a request (the data for GET and DELETE requests)
    # @api private
    # @param http_method [Symbol] the HTTP method
    # @param data [Hash, Array, String] the query parameters or request body
    # @return [Hash] the query parameters
    def query_params(http_method, data)
      return {} unless %i[get delete].include?(http_method)

      data #: Hash[Symbol | String, untyped]
    end

    # The body for a request (the data for POST and PUT requests)
    # @api private
    # @param http_method [Symbol] the HTTP method
    # @param data [Hash, Array, String] the query parameters or request body
    # @param content_type [String] the content type of the body
    # @return [Hash, Array, String, nil] the request body
    def request_body(http_method, data, content_type)
      return if %i[get delete].include?(http_method)

      body_for(data, content_type)
    end

    # Convert a Hash body to multipart fields for a multipart content type
    # @api private
    # @param data [Hash, Array, String] the request body
    # @param content_type [String] the content type of the body
    # @return [Hash, Array, String] the request body
    def body_for(data, content_type)
      return data unless data.is_a?(Hash)

      case content_type
      when RequestBuilder::MULTIPART_FORM_DATA then data.to_a
      else data
      end
    end
  end
end
