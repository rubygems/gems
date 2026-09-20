module Gems
  # Wraps the IO that receives HTTP debug output, redacting the credentials it would otherwise write in the clear
  #
  # Net::HTTP writes every request it sends to the debug output, headers and body alike, which carry the API key,
  # the basic authentication credentials, the one-time passcode, and the OIDC ID token of a token exchange. Those
  # values are replaced before they reach the IO, so that debug output can be kept where the credentials should not
  # be.
  #
  # @api private
  class RedactedOutput
    # The value written in place of a credential
    REDACTION = "[REDACTED]".freeze
    # The patterns of the credentials the library sends, each capturing what introduces the value it redacts
    #
    # Net::HTTP dumps a request as one escaped string, in which a header is preceded by an escaped newline and its
    # value runs to the next one, and it capitalizes the header names it writes, so OTP is written as Otp. The token
    # exchange sends the ID token as the jwt field of a JSON body, whose quotes the same dump escapes.
    CREDENTIALS = [
      /(\\n(?:Authorization|OTP): )[^\\]*/i,
      /(\\"jwt\\":\\")[^\\]*/
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
