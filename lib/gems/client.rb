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
      get("/api/v1/gems/search.json", options.merge(:query => query))
    end
  end
end
