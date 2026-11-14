# frozen_string_literal: true

require "uri"

module Gems
  # Checks and compares the URLs a host, a proxy, and a redirect are given as, mixed into the configuration, the
  # client, the connection, and the redirect handler
  #
  # A URL is checked where it is assigned rather than when a request is made with it, so that the error names the
  # assignment that was wrong instead of the call that happened to send the next request. The value that is rejected
  # is left as it was.
  #
  # @api private
  module URLValidation
    private

    # Check that a host is a URL requests can be sent to
    #
    # A host that carries a user and password, such as "https://user:pass@gems.example.com", is refused: Net::HTTP
    # sends neither, so the requests would go without the credentials the caller meant to send, and the host is
    # shown by {Client#inspect} and in error messages, which would show the password. The message the host is
    # refused with leaves them out.
    #
    # @api private
    # @param host [String] the host, including scheme
    # @return [String] the host
    # @raise [ArgumentError] if the host is not an HTTP or HTTPS URL, or carries a user and password
    def validate_host(host)
      raise ArgumentError, "Invalid host: #{redact(host.to_s)}" unless http_url?(host)
      if URI(host).userinfo
        raise ArgumentError, "Invalid host: #{redact(host)} carries a user and password, which are not sent; " \
          "give them as username: and password:"
      end

      host
    end

    # Parse and validate a proxy URL
    #
    # @api private
    # @param proxy_url [String] the proxy URL
    # @return [URI::HTTP] the proxy URI
    # @raise [ArgumentError] if the proxy URL is not a valid HTTP or HTTPS URL; the message leaves out its user and
    #   password
    def parse_proxy_uri(proxy_url)
      proxy_uri = URI(proxy_url)
      raise ArgumentError, "Invalid proxy URL: #{redact(proxy_url)}" unless proxy_uri.is_a?(URI::HTTP)

      proxy_uri
    rescue URI::InvalidURIError
      raise ArgumentError, "Invalid proxy URL: #{redact(proxy_url)}"
    end

    # Whether a host is an HTTP or HTTPS URL with a host
    # @api private
    # @param host [Object] the host
    # @return [Boolean] whether the host is a URL requests can be sent to
    def http_url?(host)
      uri = URI(host)
      uri.is_a?(URI::HTTP) && !uri.host.to_s.empty?
    rescue ArgumentError, URI::InvalidURIError
      false
    end

    # Whether two URLs share a scheme, host, and port
    #
    # A URL is read as a URI, so a host given as a String and the URI a redirect leads to are compared the same way.
    #
    # @api private
    # @param url [String, URI::Generic] one URL
    # @param other [String, URI::Generic] the other URL
    # @return [Boolean] whether the URLs share an origin
    def same_origin?(url, other)
      origin(url).eql?(origin(other))
    end

    # Whether a URL is the host's own, at or under the path the host names
    #
    # The path is compared as well as the origin, so that a URL climbing out of the prefix a host carries, such as
    # "../.." for "https://gems.example.com/rubygems", is told from one the host was pointed at, as a URL of
    # another scheme, host, or port is. The prefix itself is on the host, whether or not the host is spelled with a
    # trailing slash, so "https://gems.example.com/tenant-a" is on "https://gems.example.com/tenant-a/".
    #
    # A host that carries no prefix names the whole of its origin, so every URL of that origin is on it: the
    # credentials of a request to an unprefixed host are the origin's to hold, wherever on the origin a path
    # climbs to, and a value escaped into a segment of a path (see {PathEscaping}) stays a segment of it.
    #
    # A URL whose path has a "." or ".." segment is not on a host that carries a prefix. Ruby resolves those
    # segments only when it joins a relative reference, so an absolute URL such as
    # "https://gems.example.com/gems/../admin" keeps them, and its path starts with the prefix while a server or
    # a proxy that resolves them routes it outside. The segments are read the way a server that decodes the path
    # reads them: the path is decoded before its segments are read, and each segment is read apart from every
    # separator it carries, so a segment that decodes to "." or ".." ("%2e%2e"), or to more segments than the
    # one it spells ("%2e%2e%2f"), or that carries the separator of a server that splits on backslashes or
    # strips the parameters after a semicolon, is refused rather than read for what it spells. A path that
    # cannot be decoded is refused the same way, since a server that decodes it may read it another way.
    #
    # The paths are read once the origins are known to match, so a URL that has none, such as a "mailto:" URL,
    # is answered by the comparison of the origins rather than by reading the path it does not have.
    #
    # @api private
    # @param uri [URI::Generic] the URL, as the URI it was read as
    # @param host [String, URI::Generic] the host, optionally carrying a path prefix
    # @return [Boolean] whether the URL is the host's own, at or under the path it names
    def on_host?(uri, host)
      return false unless same_origin?(uri, host)

      host_path = URI(host).path #: String
      prefix = decoded(host_path).chomp("/")
      return true if prefix.empty?

      uri_path = uri.path #: String
      path = decoded(uri_path)
      return false if segments_of(path).any?(DOT_SEGMENT)

      path.eql?(prefix) || path.start_with?("#{prefix}/")
    end

    # The segments a decoded path is made of
    #
    # The path is split on the slashes it carries, and on the backslashes some servers carry as separators of
    # their own, and each segment is split on the semicolons it carries, as a server that strips the matrix
    # parameters of a path reads it. The segments a path spells for a server that resolves them are what it is
    # read by, so every way a segment can carry a separator of its own is split apart.
    #
    # @api private
    # @param path [String] the decoded path
    # @return [Array<String>] the segments of the path, split apart from every separator
    def segments_of(path)
      path.split(SEPARATOR).flat_map { |segment| segment.split(";") }
    end

    # The separators a decoded path may carry: a slash, and a backslash, each as a segment of its own
    SEPARATOR = %r{[/\\]}
    # A segment of "." or "..", which a server that resolves the segments of a path climbs with
    DOT_SEGMENT = /\A\.{1,2}\z/
    private_constant :SEPARATOR, :DOT_SEGMENT

    # The path of a URL, percent-decoded, as a server that decodes it reads it
    #
    # @api private
    # @param path [String] the path of the URL, as the URI it was read as
    # @return [String] the decoded path
    def decoded(path)
      URI.decode_uri_component(path)
    end

    # The origin of a URL, with the scheme and host in lowercase
    # @api private
    # @param url [String, URI::Generic] the URL
    # @return [Array] the scheme, host, and port
    def origin(url)
      uri = URI(url).normalize
      [uri.scheme, uri.host, uri.port]
    end

    # Remove the user and password from a URL
    # @api private
    # @param url [String, nil] the URL
    # @return [String, nil] the URL without its userinfo, or nil for nil
    def redact(url)
      url&.sub(%r{(?<=//)[^/@]*@}, "")
    end
  end
end
