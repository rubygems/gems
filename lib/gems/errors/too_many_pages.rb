# frozen_string_literal: true

require_relative "error"

module Gems
  # Error raised when too many pages are enumerated
  # @api public
  class TooManyPages < Error; end
end
