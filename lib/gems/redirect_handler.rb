require "net/http"
require "uri"
require_relative "authenticator"
require_relative "connection"
require_relative "errors/too_many_redirects"
require_relative "request_builder"

module Gems
  # Handles HTTP redirects for API requests
  # @api public
  class RedirectHandler
    # Default maximum number of redirects to follow
    DEFAULT_MAX_REDIRECTS = 10
    # HTTP status codes that preserve the request method and body
    METHOD_PRESERVING_CODES = [307, 308].freeze

    # The maximum number of redirects to follow
    # @api public
    # @return [Integer] the maximum number of redirects to follow
    # @example Get or set the maximum redirects
    #   handler.max_redirects = 5
    attr_accessor :max_redirects

    # The connection for making requests
    # @api public
    # @return [Connection] the connection for making requests
    # @example Get the connection
    #   handler.connection
    attr_reader :connection

    # The request builder for creating requests
    # @api public
    # @return [RequestBuilder] the request builder for creating requests
    # @example Get the request builder
    #   handler.request_builder
    attr_reader :request_builder

    # Initialize a new RedirectHandler
    #
    # @api public
    # @param connection [Connection] the connection for making requests
    # @param request_builder [RequestBuilder] the request builder for creating requests
    # @param max_redirects [Integer] the maximum number of redirects to follow
    # @return [RedirectHandler] a new instance
    # @example Create a redirect handler
    #   handler = Gems::RedirectHandler.new(connection: conn, request_builder: builder)
    def initialize(connection: Connection.new, request_builder: RequestBuilder.new,
      max_redirects: DEFAULT_MAX_REDIRECTS)
      @connection = connection
      @request_builder = request_builder
      @max_redirects = max_redirects
    end

    # Handle redirects for an HTTP response
    #
    # @api public
    # @param response [Net::HTTPResponse] the HTTP response to handle
    # @param request [Net::HTTPRequest] the original HTTP request
    # @param authenticator [Authenticator] the authenticator for requests
    # @param redirect_count [Integer] the current redirect count
    # @return [Net::HTTPResponse] the final HTTP response after following redirects
    # @raise [TooManyRedirects] if the maximum number of redirects is exceeded
    # @example Handle a response
    #   response = handler.handle(response: resp, request: req)
    def handle(response:, request:, authenticator: Authenticator.new, redirect_count: 0)
      return response unless response.is_a?(Net::HTTPRedirection)

      raise TooManyRedirects, "Too many redirects" if redirect_count >= max_redirects

      new_request = build_request(request, build_new_uri(response, request), Integer(response.code), authenticator)
      new_response = connection.perform(request: new_request)

      handle(response: new_response, request: new_request, authenticator:, redirect_count: redirect_count + 1)
    end

    private

    # Build a new URI from the redirect response
    # @api private
    # @param response [Net::HTTPResponse] the redirect response
    # @param request [Net::HTTPRequest] the original request
    # @return [URI::Generic] the new URI
    def build_new_uri(response, request)
      # If location is relative, it will join with the original URI, otherwise it will overwrite it
      URI.join(request.uri, response.fetch("location"))
    end

    # Build a new request for the redirect
    # @api private
    # @param request [Net::HTTPRequest] the original request
    # @param uri [URI::Generic] the new URI
    # @param response_code [Integer] the HTTP response code
    # @param authenticator [Authenticator] the authenticator
    # @return [Net::HTTPRequest] the new request
    def build_request(request, uri, response_code, authenticator)
      if METHOD_PRESERVING_CODES.include?(response_code)
        request_builder.build(http_method: request.method.downcase.to_sym, uri:, body: request.body,
          content_type: request.content_type, authenticator:)
      else
        request_builder.build(http_method: :get, uri:, authenticator:)
      end
    end
  end
end
