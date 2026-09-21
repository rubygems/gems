# frozen_string_literal: true

require_relative "../identifiers"
require_relative "../json_parsing"
require_relative "../gem"

module Gems
  module API
    # The activity endpoints, which list recently added and updated gems
    #
    # Neither endpoint is paginated: each answers with the 50 gems it names, whatever query parameters it is given,
    # so there are no further pages to ask for.
    #
    # @api public
    module ActivityEndpoints
      include Identifiers
      include JSONParsing

      # Returns the 50 gems most recently added to RubyGems.org (for the first time)
      #
      # The endpoint answers with those 50 gems and no more; it has no pages.
      #
      # @api public
      # @authenticated false
      # @return [Array<Gem>]
      # @example
      #   Gems.latest
      def latest
        Gem.list(parse_json(get("/api/v1/activity/latest.json")))
      end

      # Returns the 50 most recently updated gems
      #
      # The endpoint answers with those 50 gems and no more; it has no pages.
      #
      # @api public
      # @authenticated false
      # @return [Array<Gem>]
      # @example
      #   Gems.just_updated
      def just_updated
        Gem.list(parse_json(get("/api/v1/activity/just_updated.json")))
      end
    end
  end
end
