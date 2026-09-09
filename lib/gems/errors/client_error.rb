require_relative "http_error"

module Gems
  # Base class for client errors (4xx HTTP status codes)
  class ClientError < HTTPError; end
end
