# frozen_string_literal: true

module Gems
  # Base class for authentication (no authentication)
  # @api public
  class Authenticator
    # The HTTP header name for authentication
    AUTHENTICATION_HEADER = "Authorization"
    private_constant :AUTHENTICATION_HEADER

    # Generate the authentication headers for a request
    #
    # @api public
    # @param _request [Net::HTTPRequest] the HTTP request
    # @return [Hash{String => String}] the authentication headers (empty)
    # @example Generate empty authentication headers
    #   authenticator = Gems::Authenticator.new
    #   authenticator.header(request)
    def header(_request)
      {}
    end

    # Summarize the authenticator for the console
    #
    # @api public
    # @return [String] the summary, which never includes credentials
    # @example Inspect an authenticator
    #   authenticator.inspect # => #<Gems::Authenticator>
    def inspect
      "#<#{self.class}>"
    end
  end
end
