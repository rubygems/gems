require_relative "client_error"

module Gems
  # Error raised for HTTP 401 Unauthorized responses
  class Unauthorized < ClientError; end
end
