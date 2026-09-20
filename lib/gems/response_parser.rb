require "net/http"
require_relative "errors/bad_gateway"
require_relative "errors/bad_request"
require_relative "errors/client_error"
require_relative "errors/conflict"
require_relative "errors/forbidden"
require_relative "errors/gateway_timeout"
require_relative "errors/http_error"
require_relative "errors/internal_server_error"
require_relative "errors/not_found"
require_relative "errors/server_error"
require_relative "errors/service_unavailable"
require_relative "errors/too_many_requests"
require_relative "errors/unauthorized"
require_relative "errors/unprocessable_entity"

module Gems
  # Parses HTTP responses from the RubyGems API
  # @api public
  class ResponseParser
    # Mapping of HTTP status codes to error classes
    ERROR_MAP = {
      400 => BadRequest,
      401 => Unauthorized,
      403 => Forbidden,
      404 => NotFound,
      409 => Conflict,
      422 => UnprocessableEntity,
      429 => TooManyRequests,
      500 => InternalServerError,
      502 => BadGateway,
      503 => ServiceUnavailable,
      504 => GatewayTimeout
    }.freeze

    # The error classes for the 4xx and 5xx statuses ERROR_MAP does not name
    STATUS_CLASS_ERRORS = {4 => ClientError, 5 => ServerError}.freeze

    # Parse an HTTP response
    #
    # @api public
    # @param response [Net::HTTPResponse] the HTTP response to parse
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @example Parse a response
    #   parser.parse(response: response)
    def parse(response:)
      raise error(response) unless response.is_a?(Net::HTTPSuccess)

      response.body.to_s
    end

    private

    # Create an error from a response
    # @api private
    # @param response [Net::HTTPResponse] the HTTP response
    # @return [HTTPError] the error
    def error(response)
      error_class(response).new(response:)
    end

    # Get the error class for a response
    # @api private
    # @param response [Net::HTTPResponse] the HTTP response
    # @return [Class] the error class: the one named for the status, else ClientError or ServerError for its class of
    #   status, else HTTPError
    def error_class(response)
      status = Integer(response.code)
      ERROR_MAP.fetch(status) { STATUS_CLASS_ERRORS.fetch(status / 100, HTTPError) }
    end
  end
end
