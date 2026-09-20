require_relative "../identifiers"
require_relative "../json_parsing"
require_relative "../pagination"
require_relative "../gem"

module Gems
  module API
    # The activity endpoints, which list recently added and updated gems
    # @api public
    module ActivityEndpoints
      include Identifiers
      include JSONParsing
      include Pagination

      # Returns the 50 gems most recently added to RubyGems.org (for the first time)
      #
      # @api public
      # @authenticated false
      # @param page [Integer, nil] The page of results to return.
      # @return [Array<Gem>]
      # @example
      #   Gems.latest
      def latest(page: nil)
        Gem.list(parse_json(get("/api/v1/activity/latest.json", {page:}.compact)))
      end

      # Enumerates the gems most recently added to RubyGems.org, a page at a time
      #
      # A page is requested only when the gems of the page before it have been enumerated, and the enumeration ends
      # with the first empty page.
      #
      # @api public
      # @authenticated false
      # @yield [gem] each gem, when a block is given
      # @return [Enumerator<Gem>] the gems
      # @example
      #   Gems.latest_each.first(100)
      def latest_each(&block)
        each_page(block) { |page| latest(page:) }
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
        Gem.list(parse_json(get("/api/v1/activity/just_updated.json", {page:}.compact)))
      end

      # Enumerates the most recently updated gems, a page at a time
      #
      # A page is requested only when the gems of the page before it have been enumerated, and the enumeration ends
      # with the first empty page.
      #
      # @api public
      # @authenticated false
      # @yield [gem] each gem, when a block is given
      # @return [Enumerator<Gem>] the gems
      # @example
      #   Gems.just_updated_each { |gem| puts gem.name }
      def just_updated_each(&block)
        each_page(block) { |page| just_updated(page:) }
      end
    end
  end
end
