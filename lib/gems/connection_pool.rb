require "net/http"
require_relative "idempotence"

module Gems
  # Keeps the connections a {Connection} is not using, so that a request can be sent on one that is already open
  #
  # One connection is kept for each host, so that requests made at the same time are sent on connections of their
  # own rather than waiting for one another, and the connections they opened are closed when they are given back.
  # A connection opened with settings that have since changed is closed rather than reused.
  #
  # @api private
  class ConnectionPool
    include Idempotence

    # Initialize a new ConnectionPool
    #
    # @api private
    # @return [ConnectionPool] a new instance
    # @example Create a connection pool
    #   pool = Gems::ConnectionPool.new
    def initialize
      @connections = {}
      @mutex = Mutex.new
    end

    # The connection to send a request on
    #
    # A connection kept open for the host of the request is used when the request can be sent on one, and one is
    # opened with the block otherwise.
    #
    # @api private
    # @param request [Net::HTTPRequest] the request
    # @param settings [Object] the settings a connection must have been opened with to be reused
    # @param keep_alive_timeout [Numeric] the seconds an idle connection is kept open, or zero to open one each time
    # @yield the connection to open when none is kept for the host of the request
    # @return [Net::HTTP] the connection, which is open
    # @example Take the connection to send a request on
    #   pool.checkout(request:, settings:, keep_alive_timeout: 2) { Net::HTTP.new(uri.host, uri.port) }
    def checkout(request:, settings:, keep_alive_timeout:)
      http_client = take(pool_key(request), settings) if keep_alive?(request, keep_alive_timeout)
      http_client || yield.tap(&:start)
    end

    # Keep the connection a request was sent on, or close it
    #
    # @api private
    # @param request [Net::HTTPRequest] the request
    # @param http_client [Net::HTTP] the connection it was sent on
    # @param settings [Object] the settings the connection was opened with
    # @param keep_alive_timeout [Numeric] the seconds an idle connection is kept open, or zero to close it
    # @return [void]
    # @example Give back the connection a request was sent on
    #   pool.checkin(request:, http_client:, settings:, keep_alive_timeout: 2)
    def checkin(request:, http_client:, settings:, keep_alive_timeout:)
      return discard(http_client) unless keep_alive?(request, keep_alive_timeout)

      store(pool_key(request), http_client, settings)
    end

    # Close a connection
    #
    # @api private
    # @param http_client [Net::HTTP, nil] the connection, or nil when none was opened
    # @return [void]
    # @example Close the connection a request failed on
    #   pool.discard(http_client)
    def discard(http_client)
      http_client.finish if http_client&.started?
    end

    # Take the connection kept for a key
    #
    # The connection is removed from the pool, so that it is used by one request at a time, and is given back with
    # {#store}. A connection opened with other settings is closed instead of returned.
    #
    # @api private
    # @param key [Object] the key the connection is kept under
    # @param settings [Object] the settings a connection must have been opened with to be reused
    # @return [Net::HTTP, nil] the connection, or nil when none is kept for the key
    # @example Take the connection kept for a host
    #   pool.take(["https", "rubygems.org", 443], settings)
    def take(key, settings)
      kept = @mutex.synchronize { @connections.delete(key) }
      return kept.first if kept && settings.eql?(kept.last)

      discard(kept&.first)
      nil
    end

    # Keep a connection for a key
    #
    # A connection is kept only when none is kept for the key already, so that the pool holds one connection per
    # host; a connection it cannot keep is closed.
    #
    # @api private
    # @param key [Object] the key to keep the connection under
    # @param http_client [Net::HTTP] the connection
    # @param settings [Object] the settings the connection was opened with
    # @return [Boolean] whether the connection was kept
    # @example Keep a connection for a host
    #   pool.store(["https", "rubygems.org", 443], http_client, settings)
    def store(key, http_client, settings)
      stored = @mutex.synchronize { @connections[key] = [http_client, settings] unless @connections.key?(key) }
      discard(http_client) if stored.nil?
      !stored.nil?
    end

    # Close every connection the pool keeps
    #
    # The connections are taken one at a time, so that a connection given back while the pool is closing is either
    # closed with the rest or kept for the next request, rather than dropped without being closed.
    #
    # @api private
    # @return [ConnectionPool] the pool
    # @example Close the connections of a pool
    #   pool.close
    def close
      @connections.keys.each { |key| discard(delete(key)) }
      self
    end

    private

    # Take the connection kept for a key, whatever settings it was opened with
    # @api private
    # @param key [Object] the key the connection is kept under
    # @return [Net::HTTP, nil] the connection, or nil when none is kept for the key
    def delete(key)
      entry = @mutex.synchronize { @connections.delete(key) }
      entry&.first
    end

    # Whether a request can be sent on a connection that is kept open
    #
    # The connection it is sent on is kept open afterwards too. A request that is not idempotent is sent on a
    # connection of its own and that connection is closed afterwards: Net::HTTP reconnects before it reuses a
    # connection the server has closed, and retries an idempotent request whose connection breaks, but a request
    # that is not idempotent cannot be sent again to find out whether the server received the first one.
    #
    # @api private
    # @param request [Net::HTTPRequest] the request
    # @param keep_alive_timeout [Numeric] the seconds an idle connection is kept open
    # @return [Boolean] whether the connection is kept open
    def keep_alive?(request, keep_alive_timeout)
      keep_alive_timeout.positive? && idempotent?(request)
    end

    # The key a connection is kept under, which is the host it is open to
    # @api private
    # @param request [Net::HTTPRequest] the request
    # @return [Array] the scheme, host, and port
    def pool_key(request)
      uri = request.uri
      [uri.scheme, uri.host, uri.port]
    end
  end
end
