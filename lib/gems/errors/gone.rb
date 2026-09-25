# frozen_string_literal: true

require_relative "client_error"

module Gems
  # Error raised for HTTP 410 Gone responses
  #
  # RubyGems.org answers with it from the endpoints it has retired, such as `GET /api/v1/api_key`.
  #
  # @api public
  class Gone < ClientError; end
end
