require "net/http"
require "openssl"
require "zlib"
require_relative "error"

module Gems
  # Error raised when a network error occurs
  class NetworkError < Error
    # The errors of Net::HTTP, and of the socket and TLS layers under it, that are raised as a NetworkError
    WRAPPED = [
      IOError,
      Net::HTTPBadResponse,
      Net::ProtocolError,
      OpenSSL::SSL::SSLError,
      SocketError,
      SystemCallError,
      Timeout::Error,
      Zlib::Error
    ].freeze
  end
end
