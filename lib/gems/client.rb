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
  end
end
