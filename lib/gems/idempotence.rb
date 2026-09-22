# frozen_string_literal: true

module Gems
  # Tells whether a request can be sent again, mixed into the connection pool and the retry handler
  #
  # A request that is not idempotent, such as pushing a gem, cannot be sent a second time to find out whether the
  # server received the first one, so it is neither kept on a connection that may have been closed nor retried.
  #
  # An idempotent request that asks the server to do something, such as yanking a version, is told apart from a safe
  # one that only asks it for something: sending either again leaves the server as it would have been, but a second
  # answer to a request the server has already acted on is the answer to the second one, such as the 404 of a
  # version that the attempt before it yanked (see {RetryHandler}).
  #
  # @api private
  module Idempotence
    # The HTTP methods a request can be sent again with
    IDEMPOTENT_METHODS = %w[DELETE GET HEAD OPTIONS PUT TRACE].freeze

    # The HTTP methods that ask the server for something rather than asking it to do something
    SAFE_METHODS = %w[GET HEAD OPTIONS TRACE].freeze

    private

    # Whether a request made with an HTTP method can be sent again
    #
    # The method is named rather than the request, so that a caller deciding whether to send a request again does
    # not have to have built one (see {Client#execute_request}).
    #
    # @api private
    # @param http_method [String, Symbol] the HTTP method, in either case
    # @return [Boolean] whether a request made with the method is idempotent
    def idempotent?(http_method)
      IDEMPOTENT_METHODS.include?(http_method.to_s.upcase)
    end

    # Whether a request made with an HTTP method only asks the server for something
    #
    # The method is named rather than the request, as it is for {#idempotent?}.
    #
    # @api private
    # @param http_method [String, Symbol] the HTTP method, in either case
    # @return [Boolean] whether a request made with the method is safe
    def safe?(http_method)
      SAFE_METHODS.include?(http_method.to_s.upcase)
    end
  end
end
