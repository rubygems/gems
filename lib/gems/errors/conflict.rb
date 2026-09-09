require_relative "client_error"

module Gems
  # Error raised for HTTP 409 Conflict responses
  class Conflict < ClientError; end
end
