require "uri"

module Gems
  # Escapes the values interpolated into request paths, mixed into the API endpoints
  #
  # A gem name, user handle, version number, or platform is given by the caller, and may come from somewhere the
  # caller does not control, so it is escaped rather than interpolated into a path as it is. Without escaping, a value
  # holding a slash could walk out of the endpoint it was meant for, one holding a question mark or a number sign
  # could add a query string or truncate the path, and one holding a space or a character outside ASCII would raise
  # URI::InvalidURIError when the request was built.
  #
  # @api private
  module PathEscaping
    private

    # The characters that may appear in a path segment unescaped: the unreserved characters of RFC 3986
    UNRESERVED = /[^A-Za-z0-9\-._~]/
    private_constant :UNRESERVED

    # Escape a value interpolated into a request path
    #
    # @api private
    # @param value [Object] the value, which is read as a String
    # @return [String] the value, with everything but the unreserved characters percent-encoded
    def escape(value)
      URI::DEFAULT_PARSER.escape(value.to_s, UNRESERVED) #: String
    end
  end
end
