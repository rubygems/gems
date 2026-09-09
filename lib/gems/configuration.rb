require "gems/version"
require "rubygems"
require "yaml"

module Gems
  # Global configuration for clients
  module Configuration
    # An array of valid keys in the options hash when configuring a {Gems::Client}
    VALID_OPTIONS_KEYS = %i[
      host
      id_token
      key
      otp
      password
      user_agent
      username
    ].freeze

    # Set the default API endpoint
    DEFAULT_HOST = ENV["RUBYGEMS_HOST"] || "https://rubygems.org"

    # Set the default credentials
    DEFAULT_KEY = Gem.configuration.rubygems_api_key

    # Set the default 'User-Agent' HTTP header
    DEFAULT_USER_AGENT = "Gems #{Gems::VERSION}".freeze

    attr_accessor(*VALID_OPTIONS_KEYS)

    # Reset the extending module to the default configuration
    #
    # @api private
    # @param base [Module] the module being extended
    # @return [void]
    def self.extended(base)
      base.reset
    end

    # Convenience method to allow configuration options to be set in a block
    #
    # @api public
    # @yield [self] the configuration
    # @return [self]
    # @example Configure the API key
    #   Gems.configure do |config|
    #     config.key = "701243f217cdf23b1370c7b66b65ca97"
    #   end
    def configure
      yield self
      self
    end

    # Create a hash of options and their values
    #
    # @api public
    # @return [Hash{Symbol => String, nil}] the options
    # @example Get the options
    #   Gems.options
    def options
      VALID_OPTIONS_KEYS.to_h { |key| [key, public_send(key)] }
    end

    # Reset all configuration options to defaults
    #
    # @api public
    # @return [self]
    # @example Reset the configuration
    #   Gems.reset
    def reset
      self.username = nil
      self.otp = nil
      self.password = nil
      self.host = DEFAULT_HOST
      self.id_token = nil
      self.key = DEFAULT_KEY
      self.user_agent = DEFAULT_USER_AGENT
      self
    end
  end
end
