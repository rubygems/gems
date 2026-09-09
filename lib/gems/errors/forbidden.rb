require_relative "client_error"

module Gems
  # Error raised for HTTP 403 Forbidden responses
  class Forbidden < ClientError; end
end
