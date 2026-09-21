# frozen_string_literal: true

require_relative "server_error"

module Gems
  # Error raised for HTTP 503 Service Unavailable responses
  # @api public
  class ServiceUnavailable < ServerError; end
end
