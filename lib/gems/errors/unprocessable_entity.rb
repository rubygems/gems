# frozen_string_literal: true

require_relative "client_error"

module Gems
  # Error raised for HTTP 422 Unprocessable Entity responses
  # @api public
  class UnprocessableEntity < ClientError; end
end
