# frozen_string_literal: true

require_relative "server_error"

module Gems
  # Error raised for HTTP 500 Internal Server Error responses
  # @api public
  class InternalServerError < ServerError; end
end
