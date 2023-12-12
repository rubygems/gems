require 'gems/abstract_client'

require 'gems/v1'
require 'gems/v2'

require 'gems/client'
require 'gems/configuration'

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
