require_relative "api_key"
require_relative "gem"
require_relative "owner"
require_relative "profile"
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
    # @param gem [String, Gem, Version] a gem name, gem, or version
    # @return [String, nil] the gem name
    def name_of(gem)
      case gem
      when Gem, Version then gem.name
      else gem
      end
    end

    # Resolve a version number from a number or a version
    # @api private
    # @param version [String, Version, nil] a version number or version
    # @return [String, nil] the version number
    def number_of(version)
      case version
      when Version then version.number
      else version
      end
    end

    # Resolve a platform from a version
    # @api private
    # @param version [String, Version, nil] a version number or version
    # @return [String, nil] the platform of a version, or nil for a version number
    def platform_of(version)
      case version
      when Version then version.platform
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
    def full_name_of(gem, version, platform)
      ::Gem::NameTuple.new(name_of(gem), number_of(version), platform || platform_of(version)).full_name
    end

    # Resolve a user identifier from a handle, email address, ID, owner, or profile
    # @api private
    # @param owner [String, Integer, Owner, Profile] a handle, email address, user ID, owner, or profile
    # @return [String, Integer, nil] the handle or ID, or the email address when the user has no handle
    def handle_of(owner)
      case owner
      when Owner, Profile then owner.handle || owner.email
      else owner
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

    # Resolve an API key from a key or an API key object
    # @api private
    # @param api_key [String, ApiKey, nil] a key or API key
    # @return [String, nil] the key
    def key_of(api_key)
      case api_key
      when ApiKey then api_key.key
      else api_key
      end
    end
  end
end
