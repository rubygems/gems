require "forwardable"
require_relative "v1/client"

module Gems
  # Module-level access to the RubyGems API v1
  module V1
    include AbstractClient
    extend SingleForwardable

    # @!method self.new(options = {})
    #   Alias for Gems::V1::Client.new
    #   @api public
    #   @param options [Hash] options passed to {Gems::V1::Client#initialize}
    #   @return [Gems::V1::Client] a new client
    #   @example Create a client
    #     Gems::V1.new(key: "701243f217cdf23b1370c7b66b65ca97")
    def_delegator "Gems::V1::Client", :new
  end
end
