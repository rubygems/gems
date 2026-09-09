require_relative "client_error"

module Gems
  # Error raised for HTTP 422 Unprocessable Entity responses
  class UnprocessableEntity < ClientError; end
end
