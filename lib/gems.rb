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
  #     Gems.new(key: "rubygems_701243f217cdf23b1370c7b66b65ca97")
  def_delegator "Gems::Client", :new

  def_delegators :client, *API.public_instance_methods

  # The client the API methods of the module delegate to
  #
  # The client is built from the global configuration, and built again when the configuration changes, so that what
  # it learns is kept between calls: the API key a trusted publishing ID token is exchanged for, which RubyGems.org
  # issues once per token.
  #
  # @api public
  # @return [Client] the client
  # @example Perform a raw request with the module's client
  #   Gems.client.get("/api/v1/gems/rails.json")
  def self.client
    values = configuration_values
    @client = new unless values.eql?(@client_values)
    @client_values = values
    @client
  end

  # The values of the global configuration a client is built from
  #
  # They are compared between calls to notice when the configuration changes.
  #
  # @api private
  # @return [Array<Object>] the values
  def self.configuration_values
    [host, key, username, password, otp, id_token, user_agent, open_timeout, read_timeout, write_timeout, debug_output,
      proxy_url, max_redirects]
  end
  private_class_method :configuration_values
end
