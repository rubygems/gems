# frozen_string_literal: true

require_relative "client_error"

module Gems
  # Error raised for HTTP 429 Too Many Requests responses
  # @api public
  class TooManyRequests < ClientError; end
end
