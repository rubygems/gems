# frozen_string_literal: true

require_relative "../identifiers"
require_relative "../json_parsing"
require_relative "../path_escaping"
require_relative "../downloads"
require_relative "../version"

module Gems
  module API
    # The download statistics endpoints
    # @api public
    module DownloadEndpoints
      include Identifiers
      include JSONParsing
      include PathEscaping

      # Returns the total number of downloads of all gems
      #
      # @api public
      # @authenticated false
      # @return [Integer]
      # @example
      #   Gems.total_downloads
      def total_downloads
        parse_json(get("/api/v1/downloads.json")) { |json| json.fetch("total") }
      end

      # Returns the number of downloads of a gem and of one of its versions
      #
      # The endpoint answers with the counts alone, so the version they were asked for is kept in the result, as the
      # name of a gem is kept in the versions of it that {API::VersionEndpoints#versions} returns: counts that are
      # equal are the counts of the same version only when {Downloads#full_name} says so.
      #
      # @api public
      # @authenticated false
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version. A version stands in for the
      #   version argument too, so that the downloads of a version are those of that version.
      # @param version [String, Version, nil] The version of the gem (defaults to the version given as the gem, or to
      #   the latest version).
      # @param platform [String, nil] The platform of the version, such as "java" or "x86_64-linux"; defaults to the
      #   platform of a version object, or "ruby".
      # @return [Downloads]
      # @raise [NoLatestVersion] if no version is given and the gem has no published version
      # @raise [ArgumentError] if the version was built for a Ruby ABI, which the endpoint looks up by a full name
      #   RubyGems.org answers with only for the versions {#most_downloaded} returns
      # @example
      #   Gems.downloads("rails_admin", "0.0.1").version_downloads
      # @example
      #   Gems.downloads(Gems.version("rails_admin", "0.0.1")).version_downloads
      # @example
      #   Gems.downloads("nokogiri", "1.15.0", platform: "java").version_downloads
      def downloads(gem_name, version = nil, platform: nil)
        version = version_of(gem_name, version) || latest_version(gem_name)
        full_name = full_name_of(gem_name, version, platform)
        counts = parse_json(get("/api/v1/downloads/#{escape(full_name)}.json"))
        Downloads.new({"full_name" => full_name}.merge(counts))
      end

      # Returns the top 50 downloaded gem versions of all time
      #
      # Each version's download count is available as {Version#downloads_count}.
      #
      # There is no counterpart for the versions downloaded most today: RubyGems.org retired that endpoint, and
      # `GET /api/v1/downloads/top.json` answers 410 Gone.
      #
      # @api public
      # @authenticated false
      # @return [Array<Version>]
      # @example
      #   Gems.most_downloaded.first.full_name
      def most_downloaded
        versions = parse_json(get("/api/v1/downloads/all.json")) do |json|
          json.fetch("gems").map do |version, downloads|
            version.merge("name" => gem_name_from(version), "downloads_count" => downloads)
          end
        end
        Version.list(versions)
      end

      private

      # Derive the gem name from a version's full name
      #
      # The full name is the gem name and version number, followed by the platform unless it is "ruby".
      #
      # @api private
      # @param version [Hash{String => Object}] the version attributes
      # @return [String] the gem name
      def gem_name_from(version)
        version.fetch("full_name").delete_suffix("-#{version.fetch("platform")}").delete_suffix("-#{version.fetch("number")}")
      end
    end
  end
end
