# frozen_string_literal: true

require_relative "server_error"

module Gems
  # Error raised for HTTP 504 Gateway Timeout responses
  # @api public
  class GatewayTimeout < ServerError; end
end
