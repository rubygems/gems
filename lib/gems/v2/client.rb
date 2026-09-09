require "json"
require_relative "../base_client"

module Gems
  module V2
    # A client for the RubyGems API v2
    class Client < BaseClient
      # Returns information about the given gem for a specific version
      #
      # @authenticated false
      # @param gem_name [String] The name of a gem.
      # @param version [String] The requested version of the gem.
      # @return [Hash]
      # @example
      #   Gems::V2.info 'rails', '7.0.6'
      def info(gem_name, version)
        response = get("/api/v2/rubygems/#{gem_name}/versions/#{version}.json")
        JSON.parse(response)
      rescue JSON::ParserError
        {}
      end
    end
  end
end
