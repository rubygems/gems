require "net/http"
require "uri"
require_relative "authenticator"
require_relative "configuration"

module Gems
  # Builds HTTP requests for the RubyGems API
  # @api public
  class RequestBuilder
    # Content type for form-encoded request bodies
    FORM_URLENCODED = "application/x-www-form-urlencoded".freeze
    # Content type for multipart request bodies
    MULTIPART_FORM_DATA = "multipart/form-data".freeze
    # Content type for binary request bodies
    OCTET_STREAM = "application/octet-stream".freeze
    # Mapping of HTTP method symbols to Net::HTTP classes
    HTTP_METHODS = {
      get: Net::HTTP::Get,
      post: Net::HTTP::Post,
      put: Net::HTTP::Put,
      delete: Net::HTTP::Delete
    }.freeze

    # The 'User-Agent' HTTP header sent with requests
    # @api public
    # @return [String] the user agent
    # @example Get or set the user agent
    #   builder.user_agent = "Custom User Agent"
    attr_accessor :user_agent

    # Initialize a new RequestBuilder
    #
    # @api public
    # @param user_agent [String] the 'User-Agent' HTTP header sent with requests
    # @return [RequestBuilder] a new instance
    # @example Create a request builder
    #   builder = Gems::RequestBuilder.new(user_agent: "Custom User Agent")
    def initialize(user_agent: Configuration::DEFAULT_USER_AGENT)
      @user_agent = user_agent
    end

    # Build an HTTP request
    #
    # The body may be a Hash (sent as a form-encoded body), an Array of multipart
    # fields (sent as multipart/form-data), or a String (sent with the given content type).
    #
    # @api public
    # @param http_method [Symbol] the HTTP method (:get, :post, :put, :delete)
    # @param uri [URI::Generic] the request URI
    # @param params [Hash] query parameters to append to the URI
    # @param body [Hash, Array, String, nil] the request body
    # @param content_type [String, nil] the content type for a String body (defaults to application/octet-stream)
    # @param headers [Hash] additional headers for the request
    # @param authenticator [Authenticator] the authenticator for the request
    # @return [Net::HTTPRequest] the built HTTP request
    # @raise [ArgumentError] if the HTTP method is not supported
    # @example Build a GET request
    #   builder.build(http_method: :get, uri: URI("https://rubygems.org/api/v1/gems/rails.json"))
    def build(http_method:, uri:, params: {}, body: nil, content_type: nil, headers: {}, authenticator: Authenticator.new)
      request = create_request(http_method:, uri:, params:)
      add_headers(request:, headers:)
      add_body(request:, body:, content_type:)
      add_authentication(request:, authenticator:)
      request
    end

    private

    # Create an HTTP request
    # @api private
    # @param http_method [Symbol] the HTTP method
    # @param uri [URI::Generic] the request URI
    # @param params [Hash] query parameters to append to the URI
    # @return [Net::HTTPRequest] the created request
    def create_request(http_method:, uri:, params:)
      http_method_class = HTTP_METHODS[http_method]

      raise ArgumentError, "Unsupported HTTP method: #{http_method}" unless http_method_class

      http_method_class.new(add_query_params(uri, params))
    end

    # Append query parameters to a URI
    # @api private
    # @param uri [URI::Generic] the URI
    # @param params [Hash] the query parameters
    # @return [URI::Generic] a new URI with the query parameters appended
    def add_query_params(uri, params)
      uri.dup.tap do |u|
        u.query = URI.encode_www_form(params) unless params.empty?
      end
    end

    # Add headers to a request
    # @api private
    # @param request [Net::HTTPRequest] the request
    # @param headers [Hash] additional headers
    # @return [void]
    def add_headers(request:, headers:)
      {"User-Agent" => user_agent}.merge(headers).each do |key, value|
        request[key] = value
      end
    end

    # Add a body to a request
    # @api private
    # @param request [Net::HTTPRequest] the request
    # @param body [Hash, Array, String, nil] the request body
    # @param content_type [String, nil] the content type for a String body
    # @return [void]
    def add_body(request:, body:, content_type:)
      case body
      when Hash
        request.form_data = body
      when Array
        request.set_form(body, MULTIPART_FORM_DATA)
      when String
        request.content_type = content_type || OCTET_STREAM
        request.body = body
      end
    end

    # Add authentication to a request
    # @api private
    # @param request [Net::HTTPRequest] the request
    # @param authenticator [Authenticator] the authenticator
    # @return [void]
    def add_authentication(request:, authenticator:)
      authenticator.header(request).each do |key, value|
        request[key] = value
      end
    end
  end
end
