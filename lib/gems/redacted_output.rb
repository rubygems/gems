# frozen_string_literal: true

module Gems
  # Wraps the IO that receives HTTP debug output, redacting the credentials it would otherwise write in the clear
  #
  # Net::HTTP writes every request it sends and every response it reads to the debug output, headers and body alike,
  # which carry the API key, the basic authentication credentials, the one-time passcode, the OIDC ID token of a
  # token exchange, the API key an API key or token exchange response returns, and the credentials of a proxy.
  # Those values are replaced before they reach the IO, so that debug output can be kept where the credentials
  # should not be.
  #
  # @api private
  class RedactedOutput
    # The value written in place of a credential
    REDACTION = "[REDACTED]"
    # The patterns of the credentials the library sends and receives, each capturing what introduces the value it
    # redacts
    #
    # Net::HTTP dumps a request as one escaped string, in which a header is preceded by an escaped newline and its
    # value runs to the next one, and it capitalizes the header names it writes, so OTP is written as Otp. It dumps
    # bodies the same way, so the patterns also cover the credentials a body carries: the ID token the token exchange
    # sends as the jwt field of a JSON body, the API key `update_api_key` sends as a form field, and the API key a
    # response to the API key and token exchange endpoints carries.
    #
    # The credentials of a proxy are carried by the `Proxy-Authorization` header Net::HTTP sends them as, which is
    # among the headers of a request sent through an `http://` proxy and is written again in the CONNECT request
    # that opens a TLS connection through one. That CONNECT is dumped as the buffer it is sent as, with newlines of
    # its own rather than escaped ones, so it is matched by a pattern of its own.
    CREDENTIALS = [
      /(\\n(?:Proxy-)?(?:Authorization|OTP): )[^\\]*/i,
      /(\r\n(?:Proxy-)?Authorization: )[^\r\n]*/i,
      /(\\"jwt\\":\\")[^\\]*/,
      /(api_key=)[^&\\"]*/,
      /(\\"rubygems_api_key\\":\\")[^\\]*/
    ].freeze
    private_constant :CREDENTIALS

    # The IO the redacted output is written to
    # @api private
    # @return [IO] the IO
    # @example Get the IO
    #   output.output
    attr_reader :output

    # Initialize a new RedactedOutput
    #
    # @api private
    # @param output [IO] the IO to write the redacted output to
    # @return [RedactedOutput] a new instance
    # @example Wrap an IO
    #   output = Gems::RedactedOutput.new($stderr)
    def initialize(output)
      @output = output
    end

    # Write debug output, with credentials redacted
    #
    # @api private
    # @param string [String] the debug output
    # @return [RedactedOutput] self, so that writes can be chained as they can to an IO
    # @example Write debug output
    #   output << '<- "GET / HTTP/1.1\r\nAuthorization: key\r\n\r\n"'
    def <<(string)
      output << CREDENTIALS.reduce(string) { |redacted, pattern| redacted.gsub(pattern, "\\1#{REDACTION}") }
      self
    end
  end
end
