require 'gems/version'
require 'yaml'

module Gems
  module Configuration
    # An array of valid keys in the options hash when configuring a {Gems::Client}
    VALID_OPTIONS_KEYS = [
      :format,
      :key,
      :password,
      :user_agent,
      :username,
    ]

    # The response format appended to the path if none is set
    #
    # @note JSON is preferred over XML because it is more concise and faster to parse.
    DEFAULT_FORMAT = :json

    # Attempt to automatically load credentials
    DEFAULT_KEY = begin
      YAML.load(File.read(File.expand_path("~/.gem/credentials")))[:rubygems_api_key]
    rescue Errno::ENOENT
      nil
    end

    # The value sent in the 'User-Agent' header if none is set
    DEFAULT_USER_AGENT = "Gems #{Gems::VERSION}".freeze

    attr_accessor *VALID_OPTIONS_KEYS

    # When this module is extended, set all configuration options to their default values
    def self.extended(base)
      base.reset
    end

    # Convenience method to allow configuration options to be set in a block
    def configure
      yield self
    end

    # Create a hash of options and their values
    def options
      options = {}
      VALID_OPTIONS_KEYS.each{|k| options[k] = send(k)}
      options
    end

    # Reset all configuration options to defaults
    def reset
      self.format     = DEFAULT_FORMAT
      self.key        = DEFAULT_KEY
      self.password   = nil
      self.user_agent = DEFAULT_USER_AGENT
      self.username   = nil
      self
    end
  end
end
