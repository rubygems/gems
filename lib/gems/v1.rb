require 'gems/v1/client'

module Gems
  module V1
    include AbstractClient

    # Alias for Gems::V1::Client.new
    #
    # @return [Gems::V1::Client]
    def self.new(options = {})
      Gems::V1::Client.new(options)
    end
  end
end
