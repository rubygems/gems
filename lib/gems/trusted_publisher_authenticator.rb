require "json"
require "uri"
require_relative "authenticator"
require_relative "configuration"
require_relative "connection"
require_relative "request_builder"
require_relative "response_parser"

module Gems
  # Authenticator for trusted publishing
  #
  # Exchanges an OIDC ID token for a RubyGems API key on first use and then
  # authenticates requests with that key.
  #
  # @api public
  class TrustedPublisherAuthenticator < Authenticator
    # The path of the token exchange endpoint
    EXCHANGE_TOKEN_PATH = "/api/v1/oidc/trusted_publisher/exchange_token".freeze
    # The content type of the token exchange request and response
    JSON_CONTENT_TYPE = "application/json".freeze

    # The OIDC ID token
    # @api public
    # @return [String] the OIDC ID token
    # @example Get or set the ID token
    #   authenticator.id_token = ENV.fetch("ID_TOKEN")
    attr_accessor :id_token

    # The host to exchange the token with
    # @api public
    # @return [String] the host, including scheme
    # @example Get or set the host
    #   authenticator.host = "https://rubygems.org"
    attr_accessor :host

    # The connection used for the token exchange
    # @api public
    # @return [Connection] the connection
    # @example Get or set the connection
    #   authenticator.connection = Gems::Connection.new(proxy_url: "http://proxy.example.com:8080")
    attr_accessor :connection

    # The request builder used for the token exchange
    # @api public
    # @return [RequestBuilder] the request builder
    # @example Get or set the request builder
    #   authenticator.request_builder = Gems::RequestBuilder.new(user_agent: "Custom User Agent")
    attr_accessor :request_builder

    # The API key obtained from the token exchange
    # @api public
    # @return [String, nil] the API key, or nil before the token has been exchanged
    # @example Get the exchanged API key
    #   authenticator.api_key
    attr_reader :api_key

    # Initialize a new TrustedPublisherAuthenticator
    #
    # @api public
    # @param id_token [String] the OIDC ID token
    # @param host [String] the host to exchange the token with, including scheme
    # @param connection [Connection] the connection used for the token exchange
    # @param request_builder [RequestBuilder] the request builder used for the token exchange
    # @return [TrustedPublisherAuthenticator] a new instance
    # @example Create a trusted publisher authenticator
    #   authenticator = Gems::TrustedPublisherAuthenticator.new(id_token: ENV.fetch("ID_TOKEN"))
    def initialize(id_token:, host: Configuration::DEFAULT_HOST, connection: Connection.new,
      request_builder: RequestBuilder.new)
      @id_token = id_token
      @host = host
      @connection = connection
      @request_builder = request_builder
    end

    # Generate the authentication headers for a request
    #
    # Exchanges the ID token for an API key on first use.
    #
    # @api public
    # @param _request [Net::HTTPRequest] the HTTP request
    # @return [Hash{String => String}] the authentication headers with the exchanged API key
    # @raise [HTTPError] if the token exchange fails
    # @example Generate an authentication header
    #   authenticator.header(request)
    def header(_request)
      {AUTHENTICATION_HEADER => api_key || exchange_token!.fetch("rubygems_api_key")}
    end

    # Exchange the OIDC ID token for a RubyGems API key
    #
    # @api public
    # @return [Hash] the token exchange response, including rubygems_api_key, name, scopes, and expires_at
    # @raise [HTTPError] if the token exchange fails
    # @example Exchange the ID token
    #   authenticator.exchange_token!["expires_at"]
    def exchange_token!
      request = request_builder.build(http_method: :post, uri: URI.join(host, EXCHANGE_TOKEN_PATH),
        body: JSON.generate({jwt: id_token}), content_type: JSON_CONTENT_TYPE, headers: {"Accept" => JSON_CONTENT_TYPE})
      response = connection.perform(request:)
      token = JSON.parse(ResponseParser.new.parse(response:))
      @api_key = token.fetch("rubygems_api_key")
      token
    end
  end
end
