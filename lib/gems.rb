require_relative "gems/abstract_client"
require_relative "gems/client"
require_relative "gems/configuration"
require_relative "gems/v1"
require_relative "gems/v2"
require_relative "gems/version"

# A Ruby wrapper for the RubyGems.org API
module Gems
  extend Configuration
  include AbstractClient

  # Alias for Gems::Client.new
  #
  # @return [Gems::Client]
  def self.new(options = {})
    Gems::Client.new(options)
  end
end
