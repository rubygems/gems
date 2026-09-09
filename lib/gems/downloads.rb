require_relative "resource"

module Gems
  # Download counts, as returned by the downloads endpoints
  # @api public
  class Downloads < Resource
    inspect_with :total, :version_downloads

    # @!method version_downloads
    #   The downloads of the version
    #   @api public
    #   @return [Integer, nil] the downloads of the version
    #   @example
    #     downloads.version_downloads
    attribute :version_downloads

    # @!method total
    #   The total downloads of the gem
    #   @api public
    #   @return [Integer, nil] the total downloads of the gem
    #   @example
    #     downloads.total
    attribute :total, "total_downloads"
  end
end
