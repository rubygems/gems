# frozen_string_literal: true

require "json"
require "uri"
require_relative "api_key"
require_relative "authenticator"
require_relative "configuration"
require_relative "connection"
require_relative "json_parsing"
require_relative "redirect_handler"
require_relative "request_builder"
require_relative "response_parser"
require_relative "retry_handler"

module Gems
  # Authenticator for trusted publishing
  #
  # Exchanges an OIDC ID token for a RubyGems API key on first use and then
  # authenticates requests with that key.
  #
  # The ID token and the host it is exchanged with are what an authenticator is built with, beside the connection,
  # request builder, redirect handler, and retry handler it sends the exchange with, which default to ones built for
  # the authenticator: a client hands it the ones it makes its own requests with, so that the exchange is sent with
  # the timeouts, proxy, and retries the client was configured with. The ID token is given to a client with the
  # `id_token` option, and exchanged by hand with {API::APIKeyEndpoints#exchange_trusted_publisher_token}.
  #
  # @api private
  class TrustedPublisherAuthenticator < Authenticator
    include JSONParsing

    # The path of the token exchange endpoint
    EXCHANGE_TOKEN_PATH = "/api/v1/oidc/trusted_publisher/exchange_token"
    private_constant :EXCHANGE_TOKEN_PATH

    # The OIDC ID token
    # @api private
    # @return [String] the OIDC ID token
    # @example Get the ID token
    #   authenticator.id_token
    attr_reader :id_token

    # The host to exchange the token with
    # @api private
    # @return [String] the host, including scheme
    # @example Get the host
    #   authenticator.host
    attr_reader :host

    # The connection used for the token exchange
    # @api private
    # @return [Connection] the connection
    # @example Get the connection
    #   authenticator.connection
    attr_reader :connection

    # The request builder used for the token exchange
    # @api private
    # @return [RequestBuilder] the request builder
    # @example Get the request builder
    #   authenticator.request_builder
    attr_reader :request_builder

    # The redirect handler the token exchange is followed with
    # @api private
    # @return [RedirectHandler] the redirect handler
    # @example Get the redirect handler
    #   authenticator.redirect_handler
    attr_reader :redirect_handler

    # The retry handler the token exchange is sent again with
    # @api private
    # @return [RetryHandler] the retry handler
    # @example Get the retry handler
    #   authenticator.retry_handler
    attr_reader :retry_handler

    # The API key obtained from the token exchange
    # @api private
    # @return [String, nil] the API key, or nil before the token has been exchanged
    # @example Get the exchanged API key
    #   authenticator.api_key
    attr_reader :api_key

    # Initialize a new TrustedPublisherAuthenticator
    #
    # The four that follow the ID token and the host are what the exchange is sent with, and default to ones built
    # for the authenticator (see the class).
    #
    # @api private
    # @param id_token [String] the OIDC ID token
    # @param host [String] the host to exchange the token with, including scheme
    # @param connection [Connection] the connection used for the token exchange
    # @param request_builder [RequestBuilder] the request builder used for the token exchange
    # @param redirect_handler [RedirectHandler] the redirect handler the exchange is followed with
    # @param retry_handler [RetryHandler] the retry handler the exchange is sent again with
    # @return [TrustedPublisherAuthenticator] a new instance
    # @example Create a trusted publisher authenticator
    #   authenticator = Gems::TrustedPublisherAuthenticator.new(id_token: ENV.fetch("ID_TOKEN"))
    def initialize(id_token:, host: Gems.default_host, connection: Connection.new,
      request_builder: RequestBuilder.new,
      redirect_handler: RedirectHandler.new(connection:, request_builder:),
      retry_handler: RetryHandler.new)
      @id_token = id_token
      @host = host
      @connection = connection
      @request_builder = request_builder
      @redirect_handler = redirect_handler
      @retry_handler = retry_handler
      @mutex = Mutex.new
    end

    # Generate the authentication headers for a request
    #
    # Exchanges the ID token for an API key on first use, once even when requests are made concurrently, since
    # RubyGems.org issues the key only once per token.
    #
    # @api private
    # @param _request [Net::HTTPRequest] the HTTP request
    # @return [Hash{String => String}] the authentication headers with the exchanged API key
    # @raise [HTTPError] if the token exchange fails
    # @raise [InvalidResponse] if the response is not JSON
    # @example Generate an authentication header
    #   authenticator.header(request)
    def header(_request)
      {AUTHENTICATION_HEADER => @mutex.synchronize { api_key || exchange!.key }}
    end

    # Summarize the authenticator for the console
    #
    # @api private
    # @return [String] the summary, which includes the host but not the ID token or API key
    # @example Inspect a trusted publisher authenticator
    #   authenticator.inspect # => #<Gems::TrustedPublisherAuthenticator host="https://rubygems.org">
    def inspect
      "#<#{self.class} host=#{host.inspect}>"
    end

    # Exchange the OIDC ID token for a RubyGems API key
    #
    # The redirects of the exchange are followed as those of every other request are, so that a host that answers
    # the endpoint with one is exchanged with rather than raising the {HTTPError} of the redirect. A redirect to
    # another scheme, host, or port is followed without the `Accept` header of the exchange, as it is for a request
    # of the client, and with the body only when the redirect preserves the method.
    #
    # The exchange is made under the lock that {#header} takes, so that a caller exchanging the token itself while
    # a request is being authenticated exchanges it once rather than twice, which RubyGems.org would refuse.
    #
    # @api private
    # @return [APIKey] the exchanged API key, including its name, scopes, and expiry
    # @raise [HTTPError] if the token exchange fails
    # @example Exchange the ID token
    #   authenticator.exchange_token!.expires_at
    def exchange_token!
      @mutex.synchronize { exchange! }
    end

    private

    # Exchange the ID token, under the lock its callers hold
    #
    # @api private
    # @return [APIKey] the exchanged API key, including its name, scopes, and expiry
    # @raise [HTTPError] if the token exchange fails
    def exchange!
      api_key = APIKey.new(parse_json(ResponseParser.new.parse(response: exchange_response)))
      @api_key = api_key.key
      api_key
    end

    # Send the token exchange request and follow the redirects of its response
    #
    # The exchange is sent again when the server turns it away or the network loses it, although it is a POST, so
    # that a moment of rate limiting or a dropped connection does not fail a publish; the `max_retries` of the
    # client it was built for is what it is sent again. A 429, 502, 503, or 504 answers the exchange with no key,
    # and an exchange lost to the network may have been issued one whose answer went missing, but an exchange sent
    # again for any of them either is issued a key or answers that the token is spent, where the publish would have
    # failed either way, which is why sending it again is worth it where a request that acts on a gem is not.
    #
    # @api private
    # @return [Net::HTTPResponse] the response the exchange ended at
    def exchange_response
      uri = URI.join("#{host.chomp("/")}/", EXCHANGE_TOKEN_PATH.delete_prefix("/"))
      body = JSON.generate({jwt: id_token})
      headers = {"Accept" => RequestBuilder::APPLICATION_JSON}
      request = request_builder.build(http_method: :post, uri:, body:,
        content_type: RequestBuilder::APPLICATION_JSON, headers:)
      retry_handler.handle(retry_refused: true, retry_unanswered: true, retry_lost: true) do
        redirect_handler.handle(response: connection.perform(request:), request:, body:,
          content_type: RequestBuilder::APPLICATION_JSON, headers:)
      end
    end
  end
end
