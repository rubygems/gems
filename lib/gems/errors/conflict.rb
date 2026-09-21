# frozen_string_literal: true

require_relative "client_error"

module Gems
  # Error raised for HTTP 409 Conflict responses
  # @api public
  class Conflict < ClientError; end
end
