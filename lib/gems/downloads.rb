# frozen_string_literal: true

require_relative "resource"

module Gems
  # Download counts, as returned by the downloads endpoints
  #
  # The endpoint answers with the counts alone, so {API::DownloadEndpoints#downloads} keeps the version it asked
  # about in the result as {#full_name}. Counts are compared by that and by the counts themselves, since the counts
  # are all they hold: the downloads of one gem are not the downloads of another that happens to have been
  # downloaded as many times, and the downloads of a version today are not its downloads yesterday.
  #
  # @api public
  class Downloads < Resource
    inspect_with :full_name, :total, :version_downloads

    # @!method full_name
    #   The full name of the version the counts are for
    #
    #   The name and version number of the gem, followed by its platform unless it is "ruby". The endpoint answers
    #   with the counts alone; this is the version they were asked for.
    #
    #   @api public
    #   @return [String, nil] the full name of the version, such as "nokogiri-1.15.0-java"
    #   @example
    #     downloads.full_name
    attribute :full_name

    # @!method version_downloads
    #   The downloads of the version
    #   @api public
    #   @return [Integer, nil] the downloads of the version
    #   @example
    #     downloads.version_downloads
    attribute :version_downloads

    # @!method total
    #   The total downloads of the gem
    #
    #   The downloads endpoint of a gem answers with the total under total_downloads, and the one for every gem
    #   answers with it under total, so the reader reads whichever the response it was built from carries.
    #
    #   @api public
    #   @return [Integer, nil] the total downloads of the gem
    #   @example
    #     downloads.total
    attribute :total, "total_downloads", "total"
  end
end
