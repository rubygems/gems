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
    #   Gems.information 'rails'
    def information(gem, options={})
      get("/api/v1/gems/#{gem}.json", options)
    end
    alias :info :information
  end
end
