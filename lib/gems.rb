# frozen_string_literal: true

require "forwardable"
require_relative "gems/client"
require_relative "gems/configuration"
require_relative "gems/library_version"
require_relative "gems/version"

# A Ruby wrapper for the RubyGems.org API
#
# Every public method of {API} is a method of this module too, delegated to {.client}: {API::GemEndpoints#rubygem}
# is `Gems.rubygem`, {API::VersionEndpoints#versions} is `Gems.versions`, and so on for every endpoint. They are
# delegated as the module is loaded rather than written out, so they are not listed among the methods below; {API}
# groups them into one mixin per topic, and each is documented there.
#
# The raw request methods, {Client#get} and the rest, are on the client rather than on this module, since a request
# of your own is made with {.client}.
#
# @api public
# @see API The endpoints, grouped into one mixin per topic
module Gems
  extend Configuration
  extend SingleForwardable

  # The mutex that guards the client the API methods of the module delegate to
  CLIENT_MUTEX = Mutex.new
  private_constant :CLIENT_MUTEX

  # The settings of the global configuration that are applied to the client the module has, rather than building
  # another one from them
  CONNECTION_SETTINGS = %i[user_agent open_timeout read_timeout write_timeout keep_alive_timeout debug_output
    proxy_url max_redirects max_retries max_retry_delay].freeze
  private_constant :CONNECTION_SETTINGS

  # @!method self.new(**options)
  #   Alias for Gems::Client.new
  #   @api public
  #   @param options [Hash] options passed to {Gems::Client#initialize}
  #   @yield [client] the client, which is closed once the block is done with it (see {Gems::Client.new})
  #   @return [Gems::Client, Object] a new client, or what the block returned
  #   @example Create a client
  #     Gems.new(key: "rubygems_701243f217cdf23b1370c7b66b65ca97")
  #   @example Close the connections of a client once a block is done with it
  #     Gems.new { |client| client.versions("rails") }
  def_delegator "Gems::Client", :new

  # The endpoints of {API}, each delegated to the client the module has. They are read from the module as it is
  # loaded rather than written out one by one, so YARD has none of them to document here; {API} documents each of
  # them in the mixin it belongs to.
  def_delegators :client, *API.public_instance_methods

  # The client the API methods of the module delegate to
  #
  # The client is built from the global configuration, and a change to that configuration is applied to the client it
  # has rather than building another one, which would throw away what the client learned: the API key a trusted
  # publishing ID token is exchanged for, which RubyGems.org issues once per token. A configured credential is applied
  # through the setter the client has for it, as the user agent and the timeouts are, so that assigning a passcode or
  # a password after a token has been exchanged keeps the key it was exchanged for.
  #
  # Another client is built only for what a client cannot be given: the host, the ID token, and the fallback resolved
  # for a key that has not been assigned (see {.client_values}).
  #
  # @api public
  # @return [Client] the client
  # @example Perform a raw request with the module's client
  #   Gems.client.get("/api/v1/gems/rails.json")
  def self.client
    CLIENT_MUTEX.synchronize do
      rebuild_client unless client_values.eql?(@client_values)
      apply_credential_values unless credential_values.eql?(@credential_values)
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
  # The configuration is reset while the client is forgotten rather than afterwards, so that a thread asking for the
  # client is given one built from the configuration as it was or as it has been reset, rather than one built from a
  # configuration that is half of each.
  #
  # @api public
  # @return [self]
  # @example Reset the configuration
  #   Gems.reset
  def self.reset
    CLIENT_MUTEX.synchronize do
      @client&.close
      @client_values = nil
      super
    end
  end

  # Build the client again from the global configuration
  #
  # The client being replaced is closed once the new one has been built, since no request of the module will be sent
  # on its connections again, and so that a configuration a client cannot be built from leaves the client the module
  # has open rather than closing it on the way to raising. The rest of the configuration is applied to the new client
  # afterwards, which is what records the values it was applied from.
  #
  # @api private
  # @return [Array<Object>] the settings the client was built from
  def self.rebuild_client
    client = new
    @client&.close
    @client = client
    @client_values = client_values
  end
  private_class_method :rebuild_client

  # The settings a client cannot be given without building another one
  #
  # The host is one of them, since a client resolves the API key it falls back to, and exchanges a trusted publishing
  # ID token, for the host it was built with, and so is the ID token, since the key it is exchanged for is issued
  # once per token and a client that has one cannot be given another. The fallback resolved for a key that has not
  # been assigned is the third: a client built without a key of its own resolves one for the host of each request,
  # which assigning a key to it would stop it doing, so a fallback that has changed is given to another client.
  #
  # @api private
  # @return [Array<Object>] the values
  def self.client_values
    [host, id_token, fallback_key]
  end
  private_class_method :client_values

  # The API key of the global configuration, unless one has been assigned
  #
  # @api private
  # @return [String, nil] the fallback the library resolves, or nil when a key has been assigned
  def self.fallback_key
    key unless key_configured?
  end
  private_class_method :fallback_key

  # The credentials applied to the client the module has
  #
  # @api private
  # @return [Array<Object>] the values
  def self.credential_values
    [key, username, password, otp]
  end
  private_class_method :credential_values

  # Apply the credentials of the global configuration to the client the module has
  #
  # A key is applied only when one has been assigned, since assigning a key to a client is what tells it to send
  # that key wherever it sends a request rather than resolving one for the host of each request; a fallback that has
  # changed is given to another client instead (see {.client_values}).
  #
  # @api private
  # @return [Array<Object>] the credentials applied to the client
  def self.apply_credential_values
    @client.key = key if key_configured?
    @client.username = username
    @client.password = password
    @client.otp = otp
    @credential_values = credential_values
  end
  private_class_method :apply_credential_values

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
