# frozen_string_literal: true

require "net/http"
require "uri"
require_relative "authenticator"
require_relative "connection"
require_relative "errors/too_many_redirects"
require_relative "request_builder"
require_relative "settings"
require_relative "url_validation"

module Gems
  # Handles HTTP redirects for API requests
  # @api private
  class RedirectHandler
    include Settings
    include URLValidation

    # Default maximum number of redirects to follow
    DEFAULT_MAX_REDIRECTS = 10
    # HTTP status codes that preserve the request method and body
    METHOD_PRESERVING_CODES = [307, 308].freeze
    private_constant :METHOD_PRESERVING_CODES

    # @!method max_redirects
    #   The maximum number of redirects to follow
    #   @api private
    #   @return [Integer] the maximum number of redirects to follow
    #   @example Get the maximum redirects
    #     handler.max_redirects
    # @!method max_redirects=(max_redirects)
    #   Set the maximum number of redirects to follow
    #   @api private
    #   @param max_redirects [Integer] the maximum number of redirects to follow
    #   @return [void]
    #   @raise [ArgumentError] if it is not a whole number of times, in which case the maximum is left as it was
    #   @example Set the maximum redirects
    #     handler.max_redirects = 5
    count_setting :max_redirects

    # The connection for making requests
    # @api private
    # @return [Connection] the connection for making requests
    # @example Get the connection
    #   handler.connection
    attr_reader :connection

    # The request builder for creating requests
    # @api private
    # @return [RequestBuilder] the request builder for creating requests
    # @example Get the request builder
    #   handler.request_builder
    attr_reader :request_builder

    # Initialize a new RedirectHandler
    #
    # @api private
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
      self.max_redirects = max_redirects
    end

    # Handle redirects for an HTTP response
    #
    # A redirect to another scheme, host, or port is followed without the credentials of the request, as curl and
    # browsers do, so that a redirect cannot send them to a host they were not meant for. The headers the caller
    # asked for are dropped along with them, since a header of the caller's own may carry a credential too. A later
    # redirect back to the original host does not restore either.
    #
    # A redirect that cannot be followed, such as 304 Not Modified or one whose Location header is missing, is not a
    # valid URL, or is not an HTTP or HTTPS URL, is returned as it is, so that the caller raises the HTTPError of its
    # status.
    #
    # A 307 or 308 redirect is followed with the method of the request and the body it was built from, which is
    # given as it was given to {RequestBuilder#build}, since a multipart body cannot be read back from the request.
    # One to another scheme, host, or port is not followed at all when the request has a body, and is returned as a
    # redirect that cannot be followed is: the credentials of a request are not all carried by the headers a
    # cross-origin redirect drops, since {API::APIKeyEndpoints#update_api_key} sends an API key as a form field and
    # the trusted publishing token exchange sends an ID token as a JSON field, and a body replayed to the host the
    # redirect names would take them there.
    #
    # @api private
    # @param response [Net::HTTPResponse] the HTTP response to handle
    # @param request [Net::HTTPRequest] the original HTTP request
    # @param authenticator [Authenticator] the authenticator for requests
    # @param body [Hash, Array, String, nil] the body the request was built from
    # @param content_type [String, nil] the content type the request was built with, for a String body
    # @param headers [Hash{String => String}] the headers the request was built with
    # @param redirect_count [Integer] the current redirect count
    # @return [Net::HTTPResponse] the final HTTP response after following redirects
    # @raise [TooManyRedirects] if the maximum number of redirects is exceeded
    # @example Handle a response
    #   response = handler.handle(response: resp, request: req)
    def handle(response:, request:, authenticator: Authenticator.new, body: nil, content_type: nil, headers: {},
      redirect_count: 0)
      return response unless response.is_a?(Net::HTTPRedirection)

      raise TooManyRedirects, "Too many redirects" if redirect_count >= max_redirects

      new_uri = build_new_uri(response, request)
      return response if new_uri.nil?

      follow(response:, request:, uri: new_uri, authenticator:, body:, content_type:, headers:, redirect_count:)
    end

    private

    # Send the request again to where a redirect leads
    #
    # A redirect to another origin that would replay the body is not followed, and its response is returned for the
    # caller to raise the HTTPError of (see {#handle}).
    #
    # @api private
    # @param response [Net::HTTPResponse] the redirect response
    # @param request [Net::HTTPRequest] the request that was redirected
    # @param uri [URI::HTTP] the URI the redirect leads to
    # @param authenticator [Authenticator] the authenticator for requests
    # @param body [Hash, Array, String, nil] the body the request was built from
    # @param content_type [String, nil] the content type the request was built with, for a String body
    # @param headers [Hash{String => String}] the headers the request was built with
    # @param redirect_count [Integer] the current redirect count
    # @return [Net::HTTPResponse] the final HTTP response after following redirects
    # @raise [TooManyRedirects] if the maximum number of redirects is exceeded
    def follow(response:, request:, uri:, authenticator:, body:, content_type:, headers:, redirect_count:)
      response_code = Integer(response.code)
      unless same_origin?(request.uri, uri)
        return response if replays_body?(response_code, body)

        authenticator = Authenticator.new
        headers = {} #: Hash[String, String]
      end
      new_request = build_request(request:, uri:, response_code:, authenticator:, body:, content_type:, headers:)
      new_response = connection.perform(request: new_request)
      handle(response: new_response, request: new_request, authenticator:, body:, content_type:, headers:,
        redirect_count: redirect_count + 1)
    end

    # Whether following a redirect would send the body of the request again
    #
    # Only a redirect that keeps the method carries the body; the rest are followed with a GET that has none.
    #
    # @api private
    # @param response_code [Integer] the HTTP response code
    # @param body [Hash, Array, String, nil] the body the request was built from
    # @return [Boolean] whether the body would be sent again
    def replays_body?(response_code, body)
      method_preserving?(response_code) && !body.nil?
    end

    # Whether a redirect keeps the method and body, rather than becoming a GET
    # @api private
    # @param response_code [Integer] the HTTP response code
    # @return [Boolean] whether the method and body are kept
    def method_preserving?(response_code)
      METHOD_PRESERVING_CODES.include?(response_code)
    end

    # Build a new URI from the redirect response
    # @api private
    # @param response [Net::HTTPResponse] the redirect response
    # @param request [Net::HTTPRequest] the original request
    # @return [URI::HTTP, nil] the new URI, or nil if the response has no Location header or one that is not an HTTP
    #   or HTTPS URL
    def build_new_uri(response, request)
      location = response["location"]
      return if location.nil?

      # If location is relative, it will join with the original URI, otherwise it will overwrite it
      new_uri = URI.join(request.uri, location)
      new_uri if new_uri.is_a?(URI::HTTP)
    rescue URI::InvalidURIError
      nil
    end

    # Build a new request for the redirect
    # @api private
    # @param request [Net::HTTPRequest] the original request
    # @param uri [URI::Generic] the new URI
    # @param response_code [Integer] the HTTP response code
    # @param authenticator [Authenticator] the authenticator
    # @param body [Hash, Array, String, nil] the body the original request was built from
    # @param content_type [String, nil] the content type the original request was built with
    # @param headers [Hash{String => String}] the headers the new request is built with
    # @return [Net::HTTPRequest] the new request, with the method and body of the original for a 307 or 308, or a
    #   GET without a body otherwise
    def build_request(request:, uri:, response_code:, authenticator:, body:, content_type:, headers:)
      if method_preserving?(response_code)
        request_builder.build(http_method: request.method.downcase.to_sym, uri:, body:, content_type:, authenticator:,
          headers:)
      else
        request_builder.build(http_method: :get, uri:, authenticator:, headers:)
      end
    end
  end
end
