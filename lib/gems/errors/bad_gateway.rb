# frozen_string_literal: true

require_relative "server_error"

module Gems
  # Error raised for HTTP 502 Bad Gateway responses
  # @api public
  class BadGateway < ServerError; end
end
