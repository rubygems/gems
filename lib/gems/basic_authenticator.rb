require_relative "authenticator"

module Gems
  # Authenticator for HTTP basic authentication
  # @api public
  class BasicAuthenticator < Authenticator
    # The username
    # @api public
    # @return [String] the username
    # @example Get or set the username
    #   authenticator.username = "nick@gemcutter.org"
    attr_accessor :username

    # The password
    # @api public
    # @return [String] the password
    # @example Get or set the password
    #   authenticator.password = "schwwwwing"
    attr_accessor :password

    # Initialize a new BasicAuthenticator
    #
    # @api public
    # @param username [String] the username
    # @param password [String] the password
    # @return [BasicAuthenticator] a new instance
    # @example Create a basic authenticator
    #   authenticator = Gems::BasicAuthenticator.new(username: "nick@gemcutter.org", password: "schwwwwing")
    def initialize(username:, password:)
      @username = username
      @password = password
    end

    # Generate the authentication headers for a request
    #
    # @api public
    # @param _request [Net::HTTPRequest] the HTTP request
    # @return [Hash{String => String}] the authentication headers with basic credentials
    # @example Generate a basic authentication header
    #   authenticator.header(request)
    def header(_request)
      {AUTHENTICATION_HEADER => "Basic #{["#{username}:#{password}"].pack("m0")}"}
    end

    # Summarize the authenticator for the console
    #
    # @api public
    # @return [String] the summary, which includes the username but not the password
    # @example Inspect a basic authenticator
    #   authenticator.inspect # => #<Gems::BasicAuthenticator username="nick@gemcutter.org">
    def inspect
      "#<#{self.class} username=#{username.inspect}>"
    end
  end
end
