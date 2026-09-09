require_relative "dependency"
require_relative "resource"

module Gems
  # A gem, as returned by the gem information, search, and activity endpoints
  # @api public
  class Gem < Resource
    inspect_with :name, :version

    # @!method name
    #   The name of the gem
    #   @api public
    #   @return [String, nil] the name of the gem
    #   @example
    #     gem.name
    attribute :name

    # @!method version
    #   The version number
    #   @api public
    #   @return [String, nil] the version number
    #   @example
    #     gem.version
    attribute :version

    # @!method version_created_at
    #   When the version was created
    #   @api public
    #   @return [Time, nil] when the version was created
    #   @example
    #     gem.version_created_at
    time_attribute :version_created_at

    # @!method downloads
    #   The total downloads of the gem
    #   @api public
    #   @return [Integer, nil] the total downloads of the gem
    #   @example
    #     gem.downloads
    attribute :downloads

    # @!method version_downloads
    #   The downloads of the version
    #   @api public
    #   @return [Integer, nil] the downloads of the version
    #   @example
    #     gem.version_downloads
    attribute :version_downloads

    # @!method platform
    #   The platform
    #   @api public
    #   @return [String, nil] the platform
    #   @example
    #     gem.platform
    attribute :platform

    # @!method authors
    #   The authors
    #   @api public
    #   @return [String, nil] the authors
    #   @example
    #     gem.authors
    attribute :authors

    # @!method info
    #   The description
    #   @api public
    #   @return [String, nil] the description
    #   @example
    #     gem.info
    attribute :info

    # @!method licenses
    #   The licenses
    #   @api public
    #   @return [Array<String>, nil] the licenses
    #   @example
    #     gem.licenses
    attribute :licenses

    # @!method metadata
    #   The gemspec metadata
    #   @api public
    #   @return [Hash{String => String}, nil] the gemspec metadata
    #   @example
    #     gem.metadata
    attribute :metadata

    # @!method yanked?
    #   Whether the version has been yanked
    #   @api public
    #   @return [Boolean] whether the version has been yanked
    #   @example
    #     gem.yanked?
    predicate :yanked

    # @!method sha
    #   The SHA-256 checksum of the gem file
    #   @api public
    #   @return [String, nil] the SHA-256 checksum of the gem file
    #   @example
    #     gem.sha
    attribute :sha

    # @!method spdx_identifier
    #   The SPDX license identifier
    #   @api public
    #   @return [String, nil] the SPDX license identifier
    #   @example
    #     gem.spdx_identifier
    attribute :spdx_identifier

    # @!method project_uri
    #   The project URI
    #   @api public
    #   @return [String, nil] the project URI
    #   @example
    #     gem.project_uri
    attribute :project_uri

    # @!method gem_uri
    #   The URI of the gem file
    #   @api public
    #   @return [String, nil] the URI of the gem file
    #   @example
    #     gem.gem_uri
    attribute :gem_uri

    # @!method homepage_uri
    #   The homepage URI
    #   @api public
    #   @return [String, nil] the homepage URI
    #   @example
    #     gem.homepage_uri
    attribute :homepage_uri

    # @!method wiki_uri
    #   The wiki URI
    #   @api public
    #   @return [String, nil] the wiki URI
    #   @example
    #     gem.wiki_uri
    attribute :wiki_uri

    # @!method documentation_uri
    #   The documentation URI
    #   @api public
    #   @return [String, nil] the documentation URI
    #   @example
    #     gem.documentation_uri
    attribute :documentation_uri

    # @!method mailing_list_uri
    #   The mailing list URI
    #   @api public
    #   @return [String, nil] the mailing list URI
    #   @example
    #     gem.mailing_list_uri
    attribute :mailing_list_uri

    # @!method source_code_uri
    #   The source code URI
    #   @api public
    #   @return [String, nil] the source code URI
    #   @example
    #     gem.source_code_uri
    attribute :source_code_uri

    # @!method bug_tracker_uri
    #   The bug tracker URI
    #   @api public
    #   @return [String, nil] the bug tracker URI
    #   @example
    #     gem.bug_tracker_uri
    attribute :bug_tracker_uri

    # @!method changelog_uri
    #   The changelog URI
    #   @api public
    #   @return [String, nil] the changelog URI
    #   @example
    #     gem.changelog_uri
    attribute :changelog_uri

    # @!method funding_uri
    #   The funding URI
    #   @api public
    #   @return [String, nil] the funding URI
    #   @example
    #     gem.funding_uri
    attribute :funding_uri

    # The runtime dependencies of the gem
    #
    # @api public
    # @return [Array<Dependency>] the runtime dependencies
    # @example List the runtime dependencies
    #   gem.runtime_dependencies.map(&:name)
    def runtime_dependencies
      dependencies_of("runtime")
    end

    # The development dependencies of the gem
    #
    # @api public
    # @return [Array<Dependency>] the development dependencies
    # @example List the development dependencies
    #   gem.development_dependencies.map(&:name)
    def development_dependencies
      dependencies_of("development")
    end

    private

    # The dependencies of the given type
    # @api private
    # @param type [String] the dependency type ("runtime" or "development")
    # @return [Array<Dependency>] the dependencies
    def dependencies_of(type)
      Dependency.list(attributes.dig("dependencies", type) || [])
    end
  end
end
