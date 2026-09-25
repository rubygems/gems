# frozen_string_literal: true

require_relative "client_error"

module Gems
  # Error raised for HTTP 422 Unprocessable Content responses
  #
  # RFC 9110 names the status Unprocessable Content, as RubyGems.org does, where the RFCs before it named it
  # Unprocessable Entity.
  #
  # @api public
  class UnprocessableContent < ClientError; end
end
