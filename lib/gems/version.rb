require_relative "resource"

module Gems
  # The current version of the Gems gem
  VERSION = "2.0.0".freeze

  # A version of a gem, as returned by the versions, downloads, and API v2 endpoints
  # @api public
  class Version < Resource
    inspect_with :name, :number
    identified_by :name, :number, :platform

    # @!method name
    #   The name of the gem
    #   @api public
    #   @return [String, nil] the name of the gem
    #   @example
    #     version.name
    attribute :name

    # @!method full_name
    #   The name and version number of the gem
    #   @api public
    #   @return [String, nil] the name and version number of the gem
    #   @example
    #     version.full_name
    attribute :full_name

    # @!method authors
    #   The authors
    #   @api public
    #   @return [String, nil] the authors
    #   @example
    #     version.authors
    attribute :authors

    # @!method built_at
    #   When the version was built
    #   @api public
    #   @return [Time, nil] when the version was built
    #   @example
    #     version.built_at
    time_attribute :built_at

    # @!method created_at
    #   When the version was pushed
    #   @api public
    #   @return [Time, nil] when the version was pushed
    #   @example
    #     version.created_at
    time_attribute :created_at

    # @!method description
    #   The description
    #   @api public
    #   @return [String, nil] the description
    #   @example
    #     version.description
    attribute :description

    # @!method summary
    #   The summary
    #   @api public
    #   @return [String, nil] the summary
    #   @example
    #     version.summary
    attribute :summary

    # @!method downloads_count
    #   The downloads of the version
    #   @api public
    #   @return [Integer, nil] the downloads of the version
    #   @example
    #     version.downloads_count
    attribute :downloads_count

    # @!method platform
    #   The platform
    #   @api public
    #   @return [String, nil] the platform
    #   @example
    #     version.platform
    attribute :platform

    # @!method prerelease?
    #   Whether the version is a prerelease
    #   @api public
    #   @return [Boolean] whether the version is a prerelease
    #   @example
    #     version.prerelease?
    predicate :prerelease

    # @!method yanked?
    #   Whether the version has been yanked
    #   @api public
    #   @return [Boolean] whether the version has been yanked
    #   @example
    #     version.yanked?
    predicate :yanked

    # @!method licenses
    #   The licenses
    #   @api public
    #   @return [Array<String>, nil] the licenses
    #   @example
    #     version.licenses
    attribute :licenses

    # @!method requirements
    #   The external requirements
    #   @api public
    #   @return [Array<String>, nil] the external requirements
    #   @example
    #     version.requirements
    attribute :requirements

    # @!method ruby_version
    #   The required Ruby version
    #   @api public
    #   @return [String, nil] the required Ruby version
    #   @example
    #     version.ruby_version
    attribute :ruby_version

    # @!method rubygems_version
    #   The required RubyGems version
    #   @api public
    #   @return [String, nil] the required RubyGems version
    #   @example
    #     version.rubygems_version
    attribute :rubygems_version

    # @!method sha
    #   The SHA-256 checksum of the gem file
    #   @api public
    #   @return [String, nil] the SHA-256 checksum of the gem file
    #   @example
    #     version.sha
    attribute :sha

    # @!method spdx_identifier
    #   The SPDX license identifier
    #   @api public
    #   @return [String, nil] the SPDX license identifier
    #   @example
    #     version.spdx_identifier
    attribute :spdx_identifier

    # @!method metadata
    #   The gemspec metadata
    #   @api public
    #   @return [Hash{String => String}, nil] the gemspec metadata
    #   @example
    #     version.metadata
    attribute :metadata

    # @!method number
    #   The version number
    #   @api public
    #   @return [String, nil] the version number
    #   @example
    #     version.number
    attribute :number
  end
end
