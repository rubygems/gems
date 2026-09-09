require "gems/abstract_client"

require "gems/v1"
require "gems/v2"

require "gems/client"
require "gems/configuration"

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
