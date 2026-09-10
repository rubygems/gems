require "json"
require_relative "../identifiers"
require_relative "../gem"

module Gems
  module API
    # The activity endpoints, which list recently added and updated gems
    # @api public
    module ActivityEndpoints
      include Identifiers

      # Returns the 50 gems most recently added to RubyGems.org (for the first time)
      #
      # @api public
      # @authenticated false
      # @param page [Integer, nil] The page of results to return.
      # @return [Array<Gem>]
      # @example
      #   Gems.latest
      def latest(page: nil)
        Gem.list(JSON.parse(get("/api/v1/activity/latest.json", {page:}.compact)))
      end

      # Returns the 50 most recently updated gems
      #
      # @api public
      # @authenticated false
      # @param page [Integer, nil] The page of results to return.
      # @return [Array<Gem>]
      # @example
      #   Gems.just_updated
      def just_updated(page: nil)
        Gem.list(JSON.parse(get("/api/v1/activity/just_updated.json", {page:}.compact)))
      end
    end
  end
end
