require 'gems/configuration'
require 'gems/connection'
require 'gems/request'

module Gems
  class Client
    include Gems::Connection
    include Gems::Request
    attr_accessor *Configuration::VALID_OPTIONS_KEYS

    def initialize(options={})
      options = Gems.options.merge(options)
      Configuration::VALID_OPTIONS_KEYS.each do |key|
        send("#{key}=", options[key])
      end
    end

    # Returns some basic information about the given gem
    #
    # @param gem [String] The name of a gem.
    # @return [Hashie::Mash]
    # @example
    #   Gems.info 'rails'
    def info(gem)
      response = get("/api/v1/gems/#{gem}")
      format.to_s.downcase == 'xml' ? response['rubygem'] : response
    end

    # Returns an array of active gems that match the query
    #
    # @param query [String] A term to search for.
    # @return [Array<Hashie::Mash>]
    # @example
    #   Gems.search 'cucumber'
    def search(query)
      response = get("/api/v1/search", {:query => query})
      format.to_s.downcase == 'xml' ? response['rubygems'] : response
    end

    # Returns an array of gem version details
    #
    # @param gem [String] The name of a gem.
    # @return [Hashie::Mash]
    # @example
    #   Gems.versions 'coulda'
    def versions(gem)
      get("/api/v1/versions/#{gem}", {}, :json)
    end

    # Returns the number of downloads by day for a particular gem version
    #
    # @param gem [String] The name of a gem.
    # @param version [String] The version of a gem.
    # @return [Hashie::Mash]
    # @example
    #   Gems.downloads 'coulda', '0.6.3'
    def downloads(gem, version)
      get("/api/v1/versions/#{gem}-#{version}/downloads", {}, :json)
    end

    # Returns an array of hashes for all versions of given gems
    #
    # @param gems [Array] A list of gem names
    # @return [Array]
    # @example
    #   Gems.dependencies 'rails', 'thor'
    def dependencies(*gems)
      get('/api/v1/dependencies', {:gems => gems.join(',')}, :marshal)
    end

    # Retrieve your API key using HTTP basic auth
    #
    # @return String
    # @example
    #   Gems.configure do |config|
    #     config.username = 'nick@gemcutter.org'
    #     config.password = 'schwwwwing'
    #   end
    #   Gems.api_key
    def api_key
      get('/api/v1/api_key', {}, :raw)
    end

    # List all gems that you own
    #
    # @return [Array]
    # @example
    #   Gems.configure do |config|
    #     config.key = '701243f217cdf23b1370c7b66b65ca97'
    #   end
    #   Gems.gems
    def gems
      response = get("/api/v1/gems")
      format.to_s.downcase == 'xml' ? response['rubygems'] : response
    end

    # View all owners of a gem that you own
    #
    # @param gem [String] The name of a gem.
    # @return [Array]
    # @example
    #   Gems.configure do |config|
    #     config.key = '701243f217cdf23b1370c7b66b65ca97'
    #   end
    #   Gems.owners('gemcutter')
    def owners(gem)
      get("/api/v1/gems/#{gem}/owners", {}, :json)
    end

    # List the webhooks registered under your account
    #
    # @return [Hashie::Mash]
    # @example
    #   Gems.configure do |config|
    #     config.key = '701243f217cdf23b1370c7b66b65ca97'
    #   end
    #   Gems.web_hooks
    def web_hooks
      get("/api/v1/web_hooks", {}, :json)
    end
  end
end
