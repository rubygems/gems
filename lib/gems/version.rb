# frozen_string_literal: true

require_relative "errors/invalid_response"
require_relative "resource"

module Gems
  # A version of a gem, as returned by the versions, downloads, and API v2 endpoints
  # @api public
  class Version < Resource
    inspect_with :name, :number
    identified_by :name, :number, :platform

    # Define a reader for a checksum, in hex from one endpoint and base64 from another
    #
    # @api private
    # @param name [Symbol] the name of the reader
    # @param hex_key [String] the key the checksum is in hex under
    # @param base64_key [String] the key the checksum is base64-encoded under
    # @return [Symbol] the name of the reader
    def self.checksum_attribute(name, hex_key, base64_key)
      define_method(name) do
        # @type self: Version
        return self[hex_key] if attributes.key?(hex_key)

        value = self[base64_key]
        value && decode_sha(value)
      end
      record_attribute(name)
    end

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
    predicate :yanked, "yanked", "yanked_at"

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
    attribute :ruby_version, "ruby_version", "required_ruby_version"

    # @!method rubygems_version
    #   The required RubyGems version
    #   @api public
    #   @return [String, nil] the required RubyGems version
    #   @example
    #     version.rubygems_version
    attribute :rubygems_version, "rubygems_version", "required_rubygems_version"

    # @!method sha
    #   The SHA-256 checksum of the gem file, in hex
    #
    #   The downloads endpoint returns the checksum base64-encoded under sha256, where the other endpoints return it
    #   in hex under sha, so it is decoded, and the checksum reads the same from every endpoint.
    #
    #   @api public
    #   @return [String, nil] the SHA-256 checksum of the gem file, in hex
    #   @raise [InvalidResponse] if the base64-encoded checksum cannot be decoded
    #   @example
    #     version.sha
    checksum_attribute :sha, "sha", "sha256"

    # @!method spec_sha
    #   The SHA-256 checksum of the gemspec, in hex
    #
    #   This is the checksum of the gemspec the gem was pushed with, which the index is built from, where {#sha} is
    #   the checksum of the gem file itself. It is decoded from spec_sha256 for the downloads endpoint, as {#sha} is.
    #
    #   @api public
    #   @return [String, nil] the SHA-256 checksum of the gemspec, in hex
    #   @raise [InvalidResponse] if the base64-encoded checksum cannot be decoded
    #   @example
    #     version.spec_sha
    checksum_attribute :spec_sha, "spec_sha", "spec_sha256"

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

    private

    # Decode a base64-encoded checksum to hex
    #
    # @api private
    # @param value [Object] the attribute value
    # @return [String] the checksum in hex
    # @raise [InvalidResponse] if the value is not a base64-encoded checksum
    def decode_sha(value)
      value.unpack1("m0").unpack1("H*") #: String
    rescue ArgumentError, NoMethodError
      raise InvalidResponse.new(body: value.to_s, message: "#{value.inspect} is not a base64-encoded checksum")
    end
  end
end
