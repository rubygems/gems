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
    # @api private
    # @param host [String] the host, including scheme
    # @return [String] the host
    # @raise [ArgumentError] if the host is not an HTTP or HTTPS URL
    def validate_host(host)
      raise ArgumentError, "Invalid host: #{host}" unless http_url?(host)

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
