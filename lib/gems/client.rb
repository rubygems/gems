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
    # @param options [Hash] A customizable set of options.
    # @return [Hashie::Mash]
    # @example
    #   Gems.info 'rails'
    def info(gem, options={})
      response = get("/api/v1/gems/#{gem}", options)
      format.to_s.downcase == 'xml' ? response['rubygem'] : response
    end

    # Returns an array of active gems that match the query
    #
    # @param query [String] A term to search for.
    # @param options [Hash] A customizable set of options.
    # @return [Array<Hashie::Mash>]
    # @example
    #   Gems.search 'cucumber'
    def search(query, options={})
      response = get("/api/v1/search", options.merge(:query => query))
      format.to_s.downcase == 'xml' ? response['rubygems'] : response
    end

    # Returns an array of gem version details
    #
    # @param gem [String] The name of a gem.
    # @param options [Hash] A customizable set of options.
    # @return [Hashie::Mash]
    # @example
    #   Gems.versions 'coulda'
    def versions(gem, options={})
      get("/api/v1/versions/#{gem}", options, :json)
    end

    # Returns the number of downloads by day for a particular gem version
    #
    # @param gem [String] The name of a gem.
    # @param version [String] The version of a gem.
    # @param options [Hash] A customizable set of options.
    # @return [Hashie::Mash]
    # @example
    #   Gems.downloads 'coulda', '0.6.3'
    def downloads(gem, version, options={})
      get("/api/v1/versions/#{gem}-#{version}/downloads", options, :json)
    end

    # Returns an array of hashes for all versions of given gems
    #
    # @param gems [Array] A list of gem names
    # @return [Array]
    # @example
    #   Gems.dependencies 'rails', 'thor'
    def dependencies(*gems)
      get("/api/v1/dependencies", {:gems => gems.join(',')}, :marshal)
    end
  end
end
