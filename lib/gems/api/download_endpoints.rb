require "json"
require_relative "../identifiers"
require_relative "../downloads"
require_relative "../version"

module Gems
  module API
    # The download statistics endpoints
    # @api public
    module DownloadEndpoints
      include Identifiers

      # Returns the total number of downloads of all gems
      #
      # @api public
      # @authenticated false
      # @return [Integer]
      # @example
      #   Gems.total_downloads
      def total_downloads
        JSON.parse(get("/api/v1/downloads.json")).fetch("total")
      end

      # Returns the number of downloads of a gem and of one of its versions
      #
      # @api public
      # @authenticated false
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @param version [String, Version, nil] The version of the gem (defaults to the latest version).
      # @return [Downloads]
      # @example
      #   Gems.downloads("rails_admin", "0.0.1").version_downloads
      def downloads(gem_name, version = nil)
        number = number_of(version) || latest_version(gem_name)
        Downloads.new(JSON.parse(get("/api/v1/downloads/#{name_of(gem_name)}-#{number}.json")))
      end

      # Returns the top 50 downloaded gem versions of all time
      #
      # Each version's download count is available as {Version#downloads_count}.
      #
      # @api public
      # @authenticated false
      # @return [Array<Version>]
      # @example
      #   Gems.most_downloaded.first.full_name
      def most_downloaded
        JSON.parse(get("/api/v1/downloads/all.json")).fetch("gems").map do |version, downloads|
          Version.new(version.merge("name" => gem_name_from(version), "downloads_count" => downloads))
        end
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
