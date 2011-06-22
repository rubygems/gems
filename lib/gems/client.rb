require 'gems/connection'
require 'gems/request'

module Gems
  class Client
    include Gems::Connection
    include Gems::Request

    # Returns some basic information about the given gem
    #
    # @param gem [String] The name of a gem.
    # @param options [Hash] A customizable set of options.
    # @return [Hashie::Mash]
    # @example
    #   Gems.info 'rails'
    def info(gem, options={})
      get("/api/v1/gems/#{gem}.json", options)
    end

    # Returns an array of active gems that match the query
    #
    # @param query [String] A term to search for.
    # @param options [Hash] A customizable set of options.
    # @return [Array<Hashie::Mash>]
    # @example
    #   Gems.search 'cucumber'
    def search(query, options={})
      get("/api/v1/search.json", options.merge(:query => query))
    end

    # Returns an array of gem version details
    #
    # @param gem [String] The name of a gem.
    # @param options [Hash] A customizable set of options.
    # @return [Hashie::Mash]
    # @example
    #   Gems.versions 'coulda'
    def versions(gem, options={})
      get("/api/v1/versions/#{gem}.json", options)
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
      get("/api/v1/versions/#{gem}-#{version}/downloads.json", options)
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
