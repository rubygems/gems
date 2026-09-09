require_relative "v2/client"

module Gems
  # Module-level access to the RubyGems API v2
  module V2
    include AbstractClient

    # Alias for Gems::V2::Client.new
    #
    # @return [Gems::V2::Client]
    def self.new(options = {})
      Gems::V2::Client.new(options)
    end
  end
end
