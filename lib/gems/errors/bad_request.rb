require_relative "client_error"

module Gems
  # Error raised for HTTP 400 Bad Request responses
  class BadRequest < ClientError; end
end
