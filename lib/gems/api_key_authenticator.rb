require_relative "authenticator"

module Gems
  # Authenticator for RubyGems API key authentication
  # @api public
  class APIKeyAuthenticator < Authenticator
    # The API key
    # @api public
    # @return [String] the API key
    # @example Get the API key
    #   authenticator.key = "701243f217cdf23b1370c7b66b65ca97"
    attr_reader :key

    # Initialize a new APIKeyAuthenticator
    #
    # @api public
    # @param key [String] the API key
    # @return [APIKeyAuthenticator] a new instance
    # @example Create an API key authenticator
    #   authenticator = Gems::APIKeyAuthenticator.new(key: "701243f217cdf23b1370c7b66b65ca97")
    def initialize(key:)
      @key = key
    end

    # Generate the authentication headers for a request
    #
    # @api public
    # @param _request [Net::HTTPRequest] the HTTP request
    # @return [Hash{String => String}] the authentication headers with the API key
    # @example Generate an API key authentication header
    #   authenticator.header(request)
    def header(_request)
      {AUTHENTICATION_HEADER => key}
    end
  end
end
