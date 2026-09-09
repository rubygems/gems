require_relative "client_error"

module Gems
  # Error raised for HTTP 429 Too Many Requests responses
  class TooManyRequests < ClientError; end
end
