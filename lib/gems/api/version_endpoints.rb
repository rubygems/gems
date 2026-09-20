# frozen_string_literal: true

require_relative "../errors/no_latest_version"
require_relative "../identifiers"
require_relative "../json_parsing"
require_relative "../pagination"
require_relative "../path_escaping"
require_relative "../gem"
require_relative "../version"

module Gems
  module API
    # The version endpoints, which look up the versions of a gem
    # @api public
    module VersionEndpoints
      include Identifiers
      include JSONParsing
      include Pagination
      include PathEscaping

      # Returns an array of gem version details
      #
      # @api public
      # @authenticated false
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @return [Array<Version>]
      # @example
      #   Gems.versions "coulda"
      def versions(gem_name)
        name = name_of(gem_name)
        Version.list(parse_json(get("/api/v1/versions/#{escape(name)}.json")).map { |version| version.merge("name" => name) })
      end

      # Returns the latest version number of a gem
      #
      # @api public
      # @authenticated false
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @return [String] the latest version number
      # @raise [NoLatestVersion] if the gem has no published version
      # @example
      #   Gems.latest_version "coulda"
      def latest_version(gem_name)
        response = get("/api/v1/versions/#{escape(name_of(gem_name))}/latest.json")
        version = parse_json(response) { |json| json.fetch("version") }
        # The endpoint answers 200 with "unknown" rather than 404 for a gem with no published version
        raise NoLatestVersion, "#{name_of(gem_name)} has no latest version" if version.eql?("unknown")

        version
      end

      # Returns information about the given gem for a specific version
      #
      # @api public
      # @authenticated false
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @param version [String, Version] The requested version of the gem.
      # @param platform [String, nil] The platform of the version, such as "java" or "x86_64-linux"; defaults to the
      #   platform of a version object, or "ruby".
      # @return [Version]
      # @example
      #   Gems.version "rails", "7.0.6"
      # @example
      #   Gems.version "nokogiri", "1.15.0", platform: "java"
      def version(gem_name, version, platform: nil)
        path = "/api/v2/rubygems/#{escape(name_of(gem_name))}/versions/#{escape(number_of(version))}.json"
        Version.new(parse_json(get(path, {platform: platform || platform_of(version)}.compact)))
      end

      # Returns the SHA-256 checksum of every file packaged in a specific gem version
      #
      # Only versions pushed after RubyGems.org started recording file manifests have this data.
      #
      # @api public
      # @authenticated false
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @param version [String, Version] The requested version of the gem.
      # @param platform [String, nil] The platform of the version, such as "java" or "x86_64-linux"; defaults to the
      #   platform of a version object, or "ruby".
      # @return [Hash{String => Hash{String => String}}] the checksums of each file, keyed by path
      # @example
      #   Gems.contents("rails", "8.1.3.1")["README.md"]["sha256"]
      def contents(gem_name, version, platform: nil)
        path = "/api/v2/rubygems/#{escape(name_of(gem_name))}/versions/#{escape(number_of(version))}/contents.json"
        parse_json(get(path, {platform: platform || platform_of(version)}.compact))
      end

      # Returns the sigstore attestations published with a gem version
      #
      # @api public
      # @authenticated false
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @param version [String, Version] The requested version of the gem.
      # @param platform [String, nil] The platform of the version, such as "java" or "x86_64-linux"; defaults to the
      #   platform of a version object, or "ruby".
      # @return [Array<Hash>] the sigstore bundles, empty for versions pushed without attestations
      # @example
      #   Gems.attestations("rails", "8.1.3.1").first["mediaType"]
      # @example
      #   Gems.attestations "nokogiri", "1.15.0", platform: "java"
      def attestations(gem_name, version, platform: nil)
        parse_json(get("/api/v1/attestations/#{escape(full_name_of(gem_name, version, platform))}.json"))
      end

      # Returns the gem versions created within a timeframe of up to seven days
      #
      # The results are paginated, 30 versions at a time; use the page option until an empty list is returned.
      #
      # @api public
      # @authenticated false
      # @param from [Time, String] The start of the timeframe, as a Time or an ISO 8601 string.
      # @param to [Time, String, nil] The end of the timeframe; defaults to now.
      # @param page [Integer, nil] The page of results to return.
      # @return [Array<Gem>]
      # @example
      #   Gems.timeframe_versions from: Time.now - 86_400
      def timeframe_versions(from:, to: nil, page: nil)
        params = {from: timestamp_of(from), to: timestamp_of(to), page:}.compact
        Gem.list(parse_json(get("/api/v1/timeframe_versions.json", params)))
      end

      # Enumerates the gem versions created within a timeframe, a page at a time
      #
      # The timeframe may span up to seven days. A page is requested only when the versions of the page before it
      # have been enumerated, and the enumeration ends with the first empty page.
      #
      # @api public
      # @authenticated false
      # @param from [Time, String] The start of the timeframe, as a Time or an ISO 8601 string.
      # @param to [Time, String, nil] The end of the timeframe; defaults to now.
      # @yield [gem] each version, when a block is given
      # @return [Enumerator<Gem>] the versions
      # @example
      #   Gems.timeframe_versions_each(from: Time.now - 86_400).count
      def timeframe_versions_each(from:, to: nil, &block)
        each_page(block) { |page| timeframe_versions(from:, to:, page:) }
      end
    end
  end
end
