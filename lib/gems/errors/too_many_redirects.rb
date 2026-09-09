require_relative "gem_error"

module Gems
  # Error raised when too many redirects are encountered
  class TooManyRedirects < GemError; end
end
