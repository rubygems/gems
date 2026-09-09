require_relative "error"

module Gems
  # Error raised when too many redirects are encountered
  class TooManyRedirects < Error; end
end
