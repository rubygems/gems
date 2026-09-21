# frozen_string_literal: true

module Gems
  # Base error class for all Gems errors
  # @api public
  class Error < StandardError; end

  # @deprecated Use {Error} instead.
  GemError = Error
  deprecate_constant :GemError
end
