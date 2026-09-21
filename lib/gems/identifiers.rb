# frozen_string_literal: true

require_relative "api_key"
require_relative "gem"
require_relative "owner"
require_relative "profile"
require_relative "trusted_publisher"
require_relative "version"
require_relative "web_hook"

module Gems
  # Resolves identifiers from resource objects, so API methods accept either
  #
  # @api private
  module Identifiers
    private

    # Resolve a gem name from a name, a gem, or a version
    # @api private
    # @param gem [String, Gem, Version, nil] a gem name, gem, or version
    # @return [String, nil] the gem name
    def name_of(gem)
      case gem
      when Gem, Version then gem.name
      else gem
      end
    end

    # Resolve a version number from a number, a version, or a gem
    #
    # A gem carries the number of the version the endpoint it came from answered with, which is the latest version
    # for the endpoints that answer with a gem.
    #
    # @api private
    # @param version [String, Version, Gem, nil] a version number, version, or gem
    # @return [String, nil] the version number
    def number_of(version)
      case version
      when Version then version.number
      when Gem then version.version
      else version
      end
    end

    # Resolve the version to act on from a gem argument and a version argument
    #
    # A gem or a version given as the gem stands in for a missing version when it carries a number of its own, so
    # that acting on one acts on the version it names rather than on the latest version of its gem. A gem name, and
    # a resource that carries no number, leave the version to the caller, which falls back to the latest version.
    #
    # @api private
    # @param gem [String, Gem, Version, nil] a gem name, gem, or version
    # @param version [String, Version, Gem, nil] a version number, version, or gem, or nil to use the gem when it
    #   carries a number
    # @return [String, Version, Gem, nil] the version to act on
    def version_of(gem, version)
      return version if version

      case gem
      when Gem, Version then gem unless number_of(gem).nil?
      end
    end

    # Resolve a platform from a version or a gem
    # @api private
    # @param version [String, Version, Gem, nil] a version number, version, or gem
    # @return [String, nil] the platform of a version or gem, or nil for a version number
    def platform_of(version)
      case version
      when Version, Gem then version.platform
      end
    end

    # Resolve the full name of a gem version, such as "nokogiri-1.15.0-java"
    #
    # The platform is omitted when it is "ruby".
    #
    # @api private
    # @param gem [String, Gem, Version] a gem name, gem, or version
    # @param version [String, Version] a version number or version
    # @param platform [String, nil] the platform; defaults to the platform of a version object
    # @return [String] the full name
    def full_name_of(gem, version, platform = nil)
      ::Gem::NameTuple.new(name_of(gem), number_of(version), platform || platform_of(version)).full_name
    end

    # Resolve the email parameter from a handle, email address, owner, or profile
    # @api private
    # @param owner [String, Integer, Owner, Profile] a handle, email address, user ID, owner, or profile
    # @return [String, Integer, nil] the handle, or the email address when the user has no handle
    def handle_of(owner)
      case owner
      when Owner, Profile then owner.handle || owner.email
      else owner
      end
    end

    # Resolve a user identifier for a URL path from a handle, ID, owner, or profile
    # @api private
    # @param user [String, Integer, Owner, Profile] a handle, user ID, owner, or profile
    # @return [String, Integer, nil] the handle, or the ID when the user has no handle
    def slug_of(user)
      case user
      when Owner, Profile then user.handle || user.id
      else user
      end
    end

    # Resolve a URL from a URL or a web hook
    # @api private
    # @param web_hook [String, WebHook] a URL or web hook
    # @return [String, nil] the URL
    def url_of(web_hook)
      case web_hook
      when WebHook then web_hook.url
      else web_hook
      end
    end

    # Resolve an ISO 8601 timestamp from a Time or a string
    # @api private
    # @param time [Time, String, nil] a Time, or an ISO 8601 string
    # @return [String, nil] the ISO 8601 string
    def timestamp_of(time)
      case time
      when Time then time.iso8601
      else time
      end
    end

    # Resolve the ID of a trusted publisher from an ID or a trusted publisher
    # @api private
    # @param trusted_publisher [Integer, String, TrustedPublisher] an ID, or a trusted publisher
    # @return [Integer, String, nil] the ID
    def id_of(trusted_publisher)
      case trusted_publisher
      when TrustedPublisher then trusted_publisher.id
      else trusted_publisher
      end
    end

    # Resolve an API key from a key or an API key object
    # @api private
    # @param api_key [String, APIKey, nil] a key or API key
    # @return [String, nil] the key
    def key_of(api_key)
      case api_key
      when APIKey then api_key.key
      else api_key
      end
    end
  end
end
