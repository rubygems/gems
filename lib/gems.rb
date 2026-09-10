require "forwardable"
require_relative "gems/client"
require_relative "gems/configuration"
require_relative "gems/version"

# A Ruby wrapper for the RubyGems.org API
# @api public
module Gems
  extend Configuration
  extend SingleForwardable

  # @!method self.new(**options)
  #   Alias for Gems::Client.new
  #   @api public
  #   @param options [Hash] options passed to {Gems::Client#initialize}
  #   @return [Gems::Client] a new client
  #   @example Create a client
  #     Gems.new(key: "701243f217cdf23b1370c7b66b65ca97")
  def_delegator "Gems::Client", :new

  def_delegators :new, *API.public_instance_methods
end
