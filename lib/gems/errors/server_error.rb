require_relative "http_error"

module Gems
  # Base class for server errors (5xx HTTP status codes)
  class ServerError < HTTPError; end
end
