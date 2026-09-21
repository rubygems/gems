# frozen_string_literal: true

require_relative "error"

module Gems
  # Error raised when too many redirects are encountered
  # @api public
  class TooManyRedirects < Error; end
end
