require "forwardable"
require_relative "gems/client"
require_relative "gems/configuration"
require_relative "gems/version"

# A Ruby wrapper for the RubyGems.org API
# @api public
module Gems
  extend Configuration
  extend SingleForwardable

  # The mutex that guards the client the API methods of the module delegate to
  CLIENT_MUTEX = Mutex.new
  private_constant :CLIENT_MUTEX

  # The settings of the global configuration that are applied to the client the module has, rather than building
  # another one from them
  CONNECTION_SETTINGS = %i[user_agent open_timeout read_timeout write_timeout keep_alive_timeout debug_output
    proxy_url max_redirects].freeze
  private_constant :CONNECTION_SETTINGS

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
  # The client is built from the global configuration, and built again when the credentials it was built from change,
  # so that what it learns is kept between calls: the API key a trusted publishing ID token is exchanged for, which
  # RubyGems.org issues once per token. A change to the rest of the configuration, such as the user agent or a
  # timeout, is applied to the client it has rather than building another one, which would throw that key away.
  #
  # @api public
  # @return [Client] the client
  # @example Perform a raw request with the module's client
  #   Gems.client.get("/api/v1/gems/rails.json")
  def self.client
    CLIENT_MUTEX.synchronize do
      rebuild_client unless credential_values.eql?(@credential_values)
      apply_connection_values unless connection_values.eql?(@connection_values)
      @client
    end
  end

  # Reset the global configuration and forget the client
  #
  # The client is forgotten as well as the configuration it was built from, so that what it learned from credentials
  # that have been reset, such as the API key an ID token was exchanged for, is not kept. Its connections are closed,
  # since no request of the module will be sent on them again.
  #
  # @api public
  # @return [self]
  # @example Reset the configuration
  #   Gems.reset
  def self.reset
    CLIENT_MUTEX.synchronize do
      @client&.close
      @credential_values = nil
    end
    super
  end

  # Build the client again from the global configuration
  #
  # The client being replaced is closed once the new one has been built, since no request of the module will be sent
  # on its connections again, and so that a configuration a client cannot be built from leaves the client the module
  # has open rather than closing it on the way to raising. The rest of the configuration is applied to the new client
  # afterwards, which is what records the values it was applied from.
  #
  # @api private
  # @return [Array<Object>] the credentials the client was built from
  def self.rebuild_client
    client = new
    @client&.close
    @client = client
    @credential_values = credential_values
  end
  private_class_method :rebuild_client

  # The credentials of the global configuration a client is built from
  #
  # They are compared between calls to notice when the credentials change, which a client cannot be given without
  # losing what it learned from the ones it has. The host is one of them, since the API key a client falls back to,
  # and the host a trusted publishing ID token is exchanged with, are resolved for it.
  #
  # @api private
  # @return [Array<Object>] the values
  def self.credential_values
    [host, key, username, password, otp, id_token]
  end
  private_class_method :credential_values

  # The rest of the global configuration
  #
  # These are applied to the client the module has rather than building another one.
  #
  # @api private
  # @return [Array<Object>] the values
  def self.connection_values
    CONNECTION_SETTINGS.map { |setting| public_send(setting) }
  end
  private_class_method :connection_values

  # Apply the rest of the global configuration to the client the module has
  #
  # @api private
  # @return [Array<Object>] the configuration applied to the client
  def self.apply_connection_values
    CONNECTION_SETTINGS.each { |setting| @client.public_send(:"#{setting}=", public_send(setting)) }
    @connection_values = connection_values
  end
  private_class_method :apply_connection_values
end
