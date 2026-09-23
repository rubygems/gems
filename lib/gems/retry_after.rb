# frozen_string_literal: true

require "time"

module Gems
  # Reads the `Retry-After` header of a response, for {HTTPError#retry_after} and for {RetryHandler}
  #
  # RubyGems.org sends the header with a 429 Too Many Requests response, and may send one with a 503 Service
  # Unavailable response, as a number of seconds or an HTTP date.
  #
  # @api private
  module RetryAfter
    # A `Retry-After` header that is a number of seconds, which HTTP writes in decimal digits alone
    DELTA_SECONDS = /\A-?\d+\z/
    private_constant :DELTA_SECONDS

    private

    # The seconds a response asks to wait before the request is sent again
    #
    # @api private
    # @param response [Net::HTTPResponse] the HTTP response
    # @return [Integer, nil] the seconds to wait, rounded up and never negative, or nil when the response has no
    #   `Retry-After` header or one that is neither a number of seconds nor an HTTP date
    def retry_after_of(response)
      value = response["Retry-After"]
      return if value.nil?

      seconds = DELTA_SECONDS.match?(value) ? value.to_i : (Time.httpdate(value) - Time.now).ceil
      [seconds, 0].max
    rescue ArgumentError
      nil
    end
  end
end
