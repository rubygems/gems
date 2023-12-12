require 'date'
require 'gems/configuration'
require 'gems/request'
require 'json'

module Gems
  module V2
    class Client
      include Gems::Request
      attr_accessor(*Configuration::VALID_OPTIONS_KEYS)

      def initialize(options = {})
        options = Gems.options.merge(options)
        Configuration::VALID_OPTIONS_KEYS.each do |key|
          send("#{key}=", options[key])
        end
      end

      # Returns information about the given gem for a sepcific version
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
