module Gems
  # Base error class for all Gems errors
  class Error < StandardError; end

  # @deprecated Use {Error} instead.
  GemError = Error
  deprecate_constant :GemError
end
