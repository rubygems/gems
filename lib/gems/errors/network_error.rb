# frozen_string_literal: true

require "net/http"
require "openssl"
require "timeout"
require "zlib"
require_relative "error"

module Gems
  # Error raised when a network error occurs
  # @api public
  class NetworkError < Error
    # The errors of Net::HTTP, and of the socket and TLS layers under it, that are raised as a NetworkError
    #
    # One of these is the `cause` of every NetworkError, so a timeout worth trying again can be told from a
    # connection that was refused.
    #
    # @api public
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
