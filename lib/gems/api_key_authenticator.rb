require_relative "authenticator"

module Gems
  # Authenticator for RubyGems API key authentication
  # @api public
  class ApiKeyAuthenticator < Authenticator
    # The API key
    # @api public
    # @return [String] the API key
    # @example Get or set the API key
    #   authenticator.key = "701243f217cdf23b1370c7b66b65ca97"
    attr_accessor :key

    # Initialize a new ApiKeyAuthenticator
    #
    # @api public
    # @param key [String] the API key
    # @return [ApiKeyAuthenticator] a new instance
    # @example Create an API key authenticator
    #   authenticator = Gems::ApiKeyAuthenticator.new(key: "701243f217cdf23b1370c7b66b65ca97")
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
