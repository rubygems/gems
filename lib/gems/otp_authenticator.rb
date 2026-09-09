require_relative "authenticator"

module Gems
  # Authenticator that adds a one-time passcode for multi-factor authentication
  #
  # Wraps another authenticator and adds the OTP header to its headers.
  #
  # @api public
  class OtpAuthenticator < Authenticator
    # The HTTP header name for the one-time passcode
    OTP_HEADER = "OTP".freeze

    # The authenticator providing the underlying credentials
    # @api public
    # @return [Authenticator] the wrapped authenticator
    # @example Get or set the wrapped authenticator
    #   authenticator.authenticator = Gems::ApiKeyAuthenticator.new(key: "key")
    attr_accessor :authenticator

    # The one-time passcode
    # @api public
    # @return [String] the one-time passcode
    # @example Get or set the one-time passcode
    #   authenticator.otp = "123456"
    attr_accessor :otp

    # Initialize a new OtpAuthenticator
    #
    # @api public
    # @param authenticator [Authenticator] the authenticator providing the underlying credentials
    # @param otp [String] the one-time passcode
    # @return [OtpAuthenticator] a new instance
    # @example Create an OTP authenticator around an API key authenticator
    #   authenticator = Gems::OtpAuthenticator.new(authenticator: Gems::ApiKeyAuthenticator.new(key: "key"), otp: "123456")
    def initialize(authenticator:, otp:)
      @authenticator = authenticator
      @otp = otp
    end

    # Generate the authentication headers for a request
    #
    # @api public
    # @param request [Net::HTTPRequest] the HTTP request
    # @return [Hash{String => String}] the wrapped authenticator's headers plus the OTP header
    # @example Generate authentication headers with a one-time passcode
    #   authenticator.header(request)
    def header(request)
      authenticator.header(request).merge(OTP_HEADER => otp)
    end

    # Summarize the authenticator for the console
    #
    # @api public
    # @return [String] the summary, which includes the wrapped authenticator but not the passcode
    # @example Inspect an OTP authenticator
    #   authenticator.inspect # => #<Gems::OtpAuthenticator authenticator=#<Gems::ApiKeyAuthenticator>>
    def inspect
      "#<#{self.class} authenticator=#{authenticator.inspect}>"
    end
  end
end
