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
  # Net::HTTP writes a response body as it reads it, a line for each read from the socket, so a credential the body
  # carries can be split across two of those lines, where neither half matches the pattern that redacts it. A body
  # sent in chunks is read a chunk at a time, each between the line that says how many bytes it is reading and the
  # line that says how many it read, with the size of the next chunk and the line break that ends each one read in
  # between, so a credential can be split across two chunks as well. The lines of a body are therefore held until
  # the response is done, which Net::HTTP writes a line of its own for, and the parts of the body are joined into
  # one line, written where its first part was read, before they are redacted; the lines around them are written as
  # they were. A connection with a debug output asks for its responses uncompressed (see {Connection}), since a
  # compressed body is written as the bytes it was sent as, which no pattern can find a credential in.
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

    # What Net::HTTP writes before the bytes it read from the socket, which it writes as an escaped string
    READ = '-> "'
    # What Net::HTTP writes before it reads a body, or a chunk of one, whether it reads a number of bytes or all
    READING = "reading "
    # What Net::HTTP writes once it has read a body, or a chunk of one
    DONE = "read "
    # The line break Net::HTTP reads after each chunk of a body sent in chunks, which ends the chunk rather than
    # carrying a part of the body, as it is written escaped
    CHUNK_END = '\r\n'
    private_constant :READ, :READING, :DONE, :CHUNK_END

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
    # The lines of a response body are held until the response is done, and written, with the parts of the body
    # joined, before whatever is written next.
    #
    # @api private
    # @param string [String] the debug output
    # @return [RedactedOutput] self, so that writes can be chained as they can to an IO
    # @example Write debug output
    #   output << '<- "GET / HTTP/1.1\r\nAuthorization: key\r\n\r\n"'
    def <<(string)
      if string.start_with?(READING)
        lines = @lines ||= [] #: Array[String]
        lines << string
        @reading = true
      elsif (lines = @lines)
        hold(lines, string)
      else
        write(string)
      end
      self
    end

    private

    # Hold a line of a body being read, or write the body once the response is done
    #
    # A line that is not a part of the body, nor one Net::HTTP writes between the parts of a body sent in chunks, says
    # the response is done.
    #
    # @api private
    # @param lines [Array<String>] the lines of the body held so far
    # @param string [String] the debug output
    # @return [void]
    def hold(lines, string)
      if @reading && string.start_with?(READ)
        read(lines, string)
      elsif string.start_with?(READ, DONE)
        @reading = false
        lines << string
      else
        flush(lines)
        write(string)
      end
    end

    # Hold a part of a body, joining it to the parts read before it
    #
    # The line break that ends a chunk is held as a line of its own, so that it does not come between the parts of
    # the body on either side of it.
    #
    # @api private
    # @param lines [Array<String>] the lines of the body held so far
    # @param string [String] the line Net::HTTP wrote for the part
    # @return [void]
    def read(lines, string)
      part = string.delete_prefix(READ).chomp.delete_suffix('"')
      body = @body
      if part.eql?(CHUNK_END)
        lines << string
      elsif body
        body << part
      else
        lines << (@body = part)
      end
    end

    # Write the lines of a body held so far, with its parts joined into one line
    # @api private
    # @param lines [Array<String>] the lines of the body held so far
    # @return [void]
    def flush(lines)
      body = @body
      lines.each { |line| write(line.equal?(body) ? %(#{READ}#{line}"\n) : line) }
      @lines = @body = nil
    end

    # Write a string to the IO, with credentials redacted
    # @api private
    # @param string [String] the debug output
    # @return [void]
    def write(string)
      output << CREDENTIALS.reduce(string) { |redacted, pattern| redacted.gsub(pattern, "\\1#{REDACTION}") }
    end
  end
end
