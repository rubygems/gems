module Gems
  # Tells whether a request can be sent again, mixed into the connection pool and the retry handler
  #
  # A request that is not idempotent, such as pushing a gem, cannot be sent a second time to find out whether the
  # server received the first one, so it is neither kept on a connection that may have been closed nor retried.
  #
  # @api private
  module Idempotence
    # The HTTP methods a request can be sent again with
    IDEMPOTENT_METHODS = %w[DELETE GET HEAD OPTIONS PUT TRACE].freeze

    private

    # Whether a request can be sent again
    # @api private
    # @param request [Net::HTTPRequest] the request
    # @return [Boolean] whether the request is idempotent
    def idempotent?(request)
      IDEMPOTENT_METHODS.include?(request.method)
    end
  end
end
