require_relative "server_error"

module Gems
  # Error raised for HTTP 503 Service Unavailable responses
  class ServiceUnavailable < ServerError; end
end
