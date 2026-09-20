require_relative "error"

module Gems
  # Error raised when a gem has no published version to use as its latest version
  class NoLatestVersion < Error; end
end
