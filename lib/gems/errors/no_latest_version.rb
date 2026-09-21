# frozen_string_literal: true

require_relative "error"

module Gems
  # Error raised when a gem has no published version to use as its latest version
  # @api public
  class NoLatestVersion < Error; end
end
