# frozen_string_literal: true

require_relative "client_error"

module Gems
  # Error raised for HTTP 403 Forbidden responses
  # @api public
  class Forbidden < ClientError; end
end
