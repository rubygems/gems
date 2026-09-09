require "forwardable"
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
  extend SingleForwardable

  # @!method self.new(options = {})
  #   Alias for Gems::Client.new
  #   @api public
  #   @param options [Hash] options passed to {Gems::Client#initialize}
  #   @return [Gems::Client] a new client
  #   @example Create a client
  #     Gems.new(key: "701243f217cdf23b1370c7b66b65ca97")
  def_delegator "Gems::Client", :new
end
