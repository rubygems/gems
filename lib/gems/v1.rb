require_relative "v1/client"

module Gems
  # Module-level access to the RubyGems API v1
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
