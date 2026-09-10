require "json"
require_relative "../identifiers"
require_relative "../gem"
require_relative "../request_builder"

module Gems
  module API
    # The gem endpoints, which look up, search for, push, and yank gems
    # @api public
    module GemEndpoints
      include Identifiers

      # Returns some basic information about the given gem
      #
      # @api public
      # @authenticated false
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @return [Gem]
      # @example
      #   Gems.gem "rails"
      def gem(gem_name)
        Gem.new(JSON.parse(get("/api/v1/gems/#{name_of(gem_name)}.json")))
      end

      # Returns an array of active gems that match the query
      #
      # @api public
      # @authenticated false
      # @param query [String] A term to search for.
      # @param page [Integer, nil] The page of results to return.
      # @return [Array<Gem>]
      # @example
      #   Gems.search "cucumber", page: 2
      def search(query, page: nil)
        Gem.list(JSON.parse(get("/api/v1/search.json", {query:, page:}.compact)))
      end

      # Returns the names of gems matching the query, for populating a search box
      #
      # @api public
      # @authenticated false
      # @param query [String] The query to autocomplete.
      # @return [Array<String>]
      # @example
      #   Gems.autocomplete "nokogiri"
      def autocomplete(query)
        JSON.parse(get("/api/v1/search/autocomplete", {query:}))
      end

      # List all gems that you own, or that the given user owns
      #
      # @api public
      # @authenticated true
      # @param user_handle [String, Integer, Owner, Profile, nil] The handle or ID of a user, or an owner or profile.
      # @return [Array<Gem>]
      # @example
      #   Gems.owned_gems
      def owned_gems(user_handle = nil)
        path = if user_handle
          "/api/v1/owners/#{handle_of(user_handle)}/gems.json"
        else
          "/api/v1/gems.json"
        end
        Gem.list(JSON.parse(get(path)))
      end

      # Submit a gem to RubyGems.org or another host
      #
      # @api public
      # @authenticated true
      # @param gem [File] A built gem.
      # @param host [String, nil] A RubyGems compatible host to use (defaults to the client's host).
      # @param attestations [Array<File>, nil] An array of attestations to push, or `nil`.
      # @return [String]
      # @example
      #   Gems.push File.new("pkg/gemcutter-0.2.1.gem"), host: "https://gems.example.com"
      def push(gem, host: nil, attestations: nil)
        if attestations
          post("/api/v1/gems", multipart_push_body(gem, attestations), host:)
        else
          post("/api/v1/gems", gem.read, host:)
        end
      end

      # Remove a gem from RubyGems.org's index
      #
      # @api public
      # @authenticated true
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @param version [String, Version, nil] The version of a gem (defaults to the latest version).
      # @param platform [String, nil] The platform of the gem.
      # @return [String]
      # @example
      #   Gems.yank "gemcutter", "0.2.1", platform: "x86-darwin-10"
      def yank(gem_name, version = nil, platform: nil)
        version = number_of(version) || latest_version(gem_name)
        delete("/api/v1/gems/yank", {gem_name: name_of(gem_name), version:, platform:}.compact)
      end

      # Update a previously yanked gem back into RubyGems.org's index
      #
      # @api public
      # @authenticated true
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @param version [String, Version, nil] The version of a gem (defaults to the latest version).
      # @param platform [String, nil] The platform of the gem.
      # @return [String]
      # @example
      #   Gems.unyank "gemcutter", "0.2.1", platform: "x86-darwin-10"
      def unyank(gem_name, version = nil, platform: nil)
        version = number_of(version) || latest_version(gem_name)
        put("/api/v1/gems/unyank", {gem_name: name_of(gem_name), version:, platform:}.compact)
      end

      # Returns an array of all the reverse dependencies to the given gem
      #
      # @api public
      # @authenticated false
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version
      # @param only [String, nil] Restrict the results to "development" or "runtime" dependencies.
      # @return [Array<String>]
      # @example
      #   Gems.reverse_dependencies "money", only: "runtime"
      def reverse_dependencies(gem_name, only: nil)
        JSON.parse(get("/api/v1/gems/#{name_of(gem_name)}/reverse_dependencies.json", {only:}.compact))
      end

      private

      # Build the multipart body for pushing a gem with attestations
      # @api private
      # @param gem [File] A built gem.
      # @param attestations [Array<File>] An array of attestations to push.
      # @return [Array] the multipart form fields
      def multipart_push_body(gem, attestations)
        [
          ["gem", gem.read, {filename: gem.path, content_type: RequestBuilder::OCTET_STREAM}],
          ["attestations", "[#{attestations.map(&:read).join(",")}]", {content_type: "application/json"}]
        ]
      end
    end
  end
end
