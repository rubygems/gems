require "json"
require_relative "api_key"
require_relative "downloads"
require_relative "gem"
require_relative "identifiers"
require_relative "owner"
require_relative "trusted_publisher_authenticator"
require_relative "version"
require_relative "web_hook"

module Gems
  # The RubyGems API endpoints, mixed into {Client}
  #
  # Every public method of this module is also available on the {Gems} module, which delegates to a new client.
  #
  # @api public
  module API
    include Identifiers

    # Mapping of the gem name groupings returned by the web hooks endpoint to the names used to register hooks
    WEB_HOOK_GEM_NAMES = {"all gems" => "*"}.freeze

    # Returns some basic information about the given gem
    #
    # @api public
    # @authenticated false
    # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
    # @return [Gem]
    # @example
    #   Gems.gem "rails"
    def gem(gem_name)
      Gem.new(JSON.parse(get("/api/v1/gems/#{name_of(gem_name)}.json")))
    end

    # Returns an array of active gems that match the query
    #
    # @api public
    # @authenticated false
    # @param query [String] A term to search for.
    # @param page [Integer, nil] The page of results to return.
    # @return [Array<Gem>]
    # @example
    #   Gems.search "cucumber", page: 2
    def search(query, page: nil)
      Gem.list(JSON.parse(get("/api/v1/search.json", {query:, page:}.compact)))
    end

    # Returns the names of gems matching the query, for populating a search box
    #
    # @api public
    # @authenticated false
    # @param query [String] The query to autocomplete.
    # @return [Array<String>]
    # @example
    #   Gems.autocomplete "nokogiri"
    def autocomplete(query)
      JSON.parse(get("/api/v1/search/autocomplete", {query:}))
    end

    # List all gems that you own, or that the given user owns
    #
    # @api public
    # @authenticated true
    # @param user_handle [String, Owner, nil] The handle of a user, or an owner.
    # @return [Array<Gem>]
    # @example
    #   Gems.owned_gems
    def owned_gems(user_handle = nil)
      path = if user_handle
        "/api/v1/owners/#{handle_of(user_handle)}/gems.json"
      else
        "/api/v1/gems.json"
      end
      Gem.list(JSON.parse(get(path)))
    end

    # Submit a gem to RubyGems.org or another host
    #
    # @api public
    # @authenticated true
    # @param gem [File] A built gem.
    # @param host [String, nil] A RubyGems compatible host to use (defaults to the client's host).
    # @param attestations [Array<File>, nil] An array of attestations to push, or `nil`.
    # @return [String]
    # @example
    #   Gems.push File.new("pkg/gemcutter-0.2.1.gem"), host: "https://gems.example.com"
    def push(gem, host: nil, attestations: nil)
      if attestations
        post("/api/v1/gems", multipart_push_body(gem, attestations), host:)
      else
        post("/api/v1/gems", gem.read, host:)
      end
    end

    # Remove a gem from RubyGems.org's index
    #
    # @api public
    # @authenticated true
    # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
    # @param version [String, Version, nil] The version of a gem (defaults to the latest version).
    # @param platform [String, nil] The platform of the gem.
    # @return [String]
    # @example
    #   Gems.yank "gemcutter", "0.2.1", platform: "x86-darwin-10"
    def yank(gem_name, version = nil, platform: nil)
      version = number_of(version) || latest_version(gem_name)
      delete("/api/v1/gems/yank", {gem_name: name_of(gem_name), version:, platform:}.compact)
    end

    # Update a previously yanked gem back into RubyGems.org's index
    #
    # @api public
    # @authenticated true
    # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
    # @param version [String, Version, nil] The version of a gem (defaults to the latest version).
    # @param platform [String, nil] The platform of the gem.
    # @return [String]
    # @example
    #   Gems.unyank "gemcutter", "0.2.1", platform: "x86-darwin-10"
    def unyank(gem_name, version = nil, platform: nil)
      version = number_of(version) || latest_version(gem_name)
      put("/api/v1/gems/unyank", {gem_name: name_of(gem_name), version:, platform:}.compact)
    end

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
      Version.list(JSON.parse(get("/api/v1/versions/#{name}.json")).map { |version| version.merge("name" => name) })
    end

    # Returns the latest version number of a gem
    #
    # @api public
    # @authenticated false
    # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
    # @return [String] the latest version number
    # @example
    #   Gems.latest_version "coulda"
    def latest_version(gem_name)
      JSON.parse(get("/api/v1/versions/#{name_of(gem_name)}/latest.json")).fetch("version")
    end

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

    # View all owners of a gem that you own
    #
    # @api public
    # @authenticated true
    # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
    # @return [Array<Owner>]
    # @example
    #   Gems.owners "gemcutter"
    def owners(gem_name)
      Owner.list(JSON.parse(get("/api/v1/gems/#{name_of(gem_name)}/owners.json")))
    end

    # Add an owner to a RubyGem you own, giving that user permission to manage it
    #
    # @api public
    # @authenticated true
    # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
    # @param owner [String, Owner] The email address or handle of the user you want to add, or an owner.
    # @param role [String, nil] The role to grant, "owner" or "maintainer"; defaults to "owner".
    # @return [String]
    # @example
    #   Gems.add_owner "gemcutter", "josh@technicalpickles.com"
    # @example
    #   Gems.add_owner "gemcutter", "josh@technicalpickles.com", role: "maintainer"
    def add_owner(gem_name, owner, role: nil)
      post("/api/v1/gems/#{name_of(gem_name)}/owners", {email: handle_of(owner), role:}.compact)
    end

    # Update the role of an existing owner of a RubyGem you own
    #
    # @api public
    # @authenticated true
    # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
    # @param owner [String, Owner] The email address or handle of the owner, or an owner.
    # @param role [String] The new role, "owner" or "maintainer".
    # @return [String]
    # @example
    #   Gems.update_owner "gemcutter", "josh@technicalpickles.com", role: "maintainer"
    def update_owner(gem_name, owner, role:)
      patch("/api/v1/gems/#{name_of(gem_name)}/owners", {email: handle_of(owner), role:})
    end

    # Remove a user's permission to manage a RubyGem you own
    #
    # @api public
    # @authenticated true
    # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
    # @param owner [String, Owner] The email address or handle of the user you want to remove, or an owner.
    # @return [String]
    # @example
    #   Gems.remove_owner "gemcutter", "josh@technicalpickles.com"
    def remove_owner(gem_name, owner)
      delete("/api/v1/gems/#{name_of(gem_name)}/owners", {email: handle_of(owner)})
    end

    # List the webhooks registered under your account
    #
    # Hooks registered for all gems have a gem name of "*", matching the value used to register them.
    #
    # @api public
    # @authenticated true
    # @return [Array<WebHook>]
    # @example
    #   Gems.web_hooks.map(&:url)
    def web_hooks
      JSON.parse(get("/api/v1/web_hooks.json")).flat_map do |gem_name, hooks|
        WebHook.list(hooks.map { |hook| hook.merge("gem_name" => WEB_HOOK_GEM_NAMES.fetch(gem_name, gem_name)) })
      end
    end

    # Create a webhook
    #
    # @api public
    # @authenticated true
    # @param gem_name [String, Gem] The name of a gem, or a gem. Specify "*" to add the hook to all gems.
    # @param url [String, WebHook] The URL of the web hook, or a web hook.
    # @return [String]
    # @example
    #   Gems.add_web_hook "rails", "http://example.com"
    def add_web_hook(gem_name, url)
      post("/api/v1/web_hooks", {gem_name: name_of(gem_name), url: url_of(url)})
    end

    # Remove a webhook
    #
    # @api public
    # @authenticated true
    # @param gem_name [String, Gem] The name of a gem, or a gem. Specify "*" to remove the hook from all gems.
    # @param url [String, WebHook] The URL of the web hook, or a web hook.
    # @return [String]
    # @example
    #   Gems.remove_web_hook "rails", "http://example.com"
    def remove_web_hook(gem_name, url)
      delete("/api/v1/web_hooks/remove", {gem_name: name_of(gem_name), url: url_of(url)})
    end

    # Test fire a webhook
    #
    # @api public
    # @authenticated true
    # @param gem_name [String, Gem] The name of a gem, or a gem. Specify "*" to fire the hook for all gems.
    # @param url [String, WebHook] The URL of the web hook, or a web hook.
    # @return [String]
    # @example
    #   Gems.fire_web_hook "rails", "http://example.com"
    def fire_web_hook(gem_name, url)
      post("/api/v1/web_hooks/fire", {gem_name: name_of(gem_name), url: url_of(url)})
    end

    # Returns the 50 gems most recently added to RubyGems.org (for the first time)
    #
    # @api public
    # @authenticated false
    # @param page [Integer, nil] The page of results to return.
    # @return [Array<Gem>]
    # @example
    #   Gems.latest
    def latest(page: nil)
      Gem.list(JSON.parse(get("/api/v1/activity/latest.json", {page:}.compact)))
    end

    # Returns the 50 most recently updated gems
    #
    # @api public
    # @authenticated false
    # @param page [Integer, nil] The page of results to return.
    # @return [Array<Gem>]
    # @example
    #   Gems.just_updated
    def just_updated(page: nil)
      Gem.list(JSON.parse(get("/api/v1/activity/just_updated.json", {page:}.compact)))
    end

    # Create an API key using HTTP basic auth
    #
    # The key is only returned once, so store it somewhere safe.
    #
    # @api public
    # @authenticated true
    # @param name [String] A name for the key.
    # @param scopes [Hash{Symbol => Boolean, String}] Scopes and settings for the key: push_rubygem, yank_rubygem,
    #   index_rubygems, add_owner, remove_owner, access_webhooks, mfa (require a one-time passcode), expires_at, and
    #   rubygem_name (restrict the key to a single gem).
    # @return [ApiKey] the new API key
    # @example
    #   Gems.configure do |config|
    #     config.username = "nick@gemcutter.org"
    #     config.password = "schwwwwing"
    #   end
    #   Gems.create_api_key("ci-push", push_rubygem: true).key
    def create_api_key(name, **scopes)
      ApiKey.new(JSON.parse(post("/api/v1/api_key.json", {**scopes, name:})))
    end

    # Update the scopes of an API key using HTTP basic auth
    #
    # @api public
    # @authenticated true
    # @param key [String, ApiKey] The API key to update.
    # @param scopes [Hash{Symbol => Boolean}] Scopes to enable or disable, such as push_rubygem or yank_rubygem.
    # @return [String]
    # @example
    #   Gems.update_api_key "701243f217cdf23b1370c7b66b65ca97", yank_rubygem: true
    def update_api_key(key, **scopes)
      patch("/api/v1/api_key", {**scopes, api_key: key_of(key)})
    end

    # Exchange an OIDC ID token for an API key via trusted publishing
    #
    # @api public
    # @authenticated false
    # @param id_token [String] The OIDC ID token.
    # @return [ApiKey] the exchanged API key, including its name, scopes, and expiry
    # @example
    #   Gems.exchange_trusted_publisher_token(ENV.fetch("ID_TOKEN")).key
    def exchange_trusted_publisher_token(id_token)
      TrustedPublisherAuthenticator.new(id_token:, host:, connection:, request_builder:).exchange_token!
    end

    # Returns an array of all the reverse dependencies to the given gem
    #
    # @api public
    # @authenticated false
    # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version
    # @param only [String, nil] Restrict the results to "development" or "runtime" dependencies.
    # @return [Array<String>]
    # @example
    #   Gems.reverse_dependencies "money", only: "runtime"
    def reverse_dependencies(gem_name, only: nil)
      JSON.parse(get("/api/v1/gems/#{name_of(gem_name)}/reverse_dependencies.json", {only:}.compact))
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
      Gem.list(JSON.parse(get("/api/v1/timeframe_versions.json", params)))
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
      path = "/api/v2/rubygems/#{name_of(gem_name)}/versions/#{number_of(version)}.json"
      Version.new(JSON.parse(get(path, {platform: platform || platform_of(version)}.compact)))
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
      path = "/api/v2/rubygems/#{name_of(gem_name)}/versions/#{number_of(version)}/contents.json"
      JSON.parse(get(path, {platform: platform || platform_of(version)}.compact))
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
      JSON.parse(get("/api/v1/attestations/#{full_name_of(gem_name, version, platform)}.json"))
    end

    private

    # Format a timestamp for a query parameter
    # @api private
    # @param time [Time, String, nil] a Time, or an ISO 8601 string
    # @return [String, nil] the ISO 8601 string
    def timestamp_of(time)
      case time
      when Time then time.iso8601
      else time
      end
    end

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

    # Build the multipart body for pushing a gem with attestations
    # @api private
    # @param gem [File] A built gem.
    # @param attestations [Array<File>] An array of attestations to push.
    # @return [Array] the multipart form fields
    def multipart_push_body(gem, attestations)
      [
        ["gem", gem.read, {filename: gem.path, content_type: RequestBuilder::OCTET_STREAM}],
        ["attestations", "[#{attestations.map(&:read).join(",")}]", {content_type: "application/json"}]
      ]
    end
  end
end
