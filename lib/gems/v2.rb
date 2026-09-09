require "forwardable"
require_relative "v2/client"

module Gems
  # Module-level access to the RubyGems API v2
  module V2
    include AbstractClient
    extend SingleForwardable

    # @!method self.new(options = {})
    #   Alias for Gems::V2::Client.new
    #   @api public
    #   @param options [Hash] options passed to {Gems::V2::Client#initialize}
    #   @return [Gems::V2::Client] a new client
    #   @example Create a client
    #     Gems::V2.new(key: "701243f217cdf23b1370c7b66b65ca97")
    def_delegator "Gems::V2::Client", :new
  end
end
