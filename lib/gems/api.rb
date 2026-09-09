require "json"
require_relative "trusted_publisher_authenticator"

module Gems
  # The RubyGems API endpoints, mixed into {Client}
  #
  # Every public method of this module is also available on the {Gems} module, which delegates to a new client.
  #
  # @api public
  module API
    # Returns some basic information about the given gem
    #
    # @api public
    # @authenticated false
    # @param gem_name [String] The name of a gem.
    # @return [Hash]
    # @example
    #   Gems.gem 'rails'
    def gem(gem_name)
      response = get("/api/v1/gems/#{gem_name}.json")
      JSON.parse(response)
    rescue JSON::ParserError
      {}
    end

    # Returns an array of active gems that match the query
    #
    # @api public
    # @authenticated false
    # @param query [String] A term to search for.
    # @param page [Integer, nil] The page of results to return.
    # @return [Array<Hash>]
    # @example
    #   Gems.search "cucumber", page: 2
    def search(query, page: nil)
      response = get("/api/v1/search.json", {query:, page:}.compact)
      JSON.parse(response)
    end

    # List all gems that you own
    #
    # @api public
    # @authenticated true
    # @param user_handle [String] The handle of a user.
    # @return [Array]
    # @example
    #   Gems.owned_gems
    def owned_gems(user_handle = nil)
      response = if user_handle
        get("/api/v1/owners/#{user_handle}/gems.json")
      else
        get("/api/v1/gems.json")
      end
      JSON.parse(response)
    end

    # Submit a gem to RubyGems.org or another host
    #
    # @api public
    # @authenticated true
    # @param gem [File] A built gem.
    # @param host [String, nil] A RubyGems compatible host to use (defaults to the client's host).
    # @param attestations [Array] An array of attestations to push, or `nil`.
    # @return [String]
    # @example
    #   Gems.push File.new("pkg/gemcutter-0.2.1.gem"), host: "https://gems.example.com"
    def push(gem, host: nil, attestations: nil)
      if attestations
        data = [
          ["gem", gem.read, {filename: gem.path, content_type: "application/octet-stream"}],
          ["attestations", "[#{attestations.map(&:read).join(",")}]", {content_type: "application/json"}]
        ] #: Array[multipart_field]
        post("/api/v1/gems", data, host:)
      else
        post("/api/v1/gems", gem.read, host:)
      end
    end

    # Remove a gem from RubyGems.org's index
    #
    # @api public
    # @authenticated true
    # @param gem_name [String] The name of a gem.
    # @param version [String, nil] The version of a gem (defaults to the latest version).
    # @param platform [String, nil] The platform of the gem.
    # @return [String]
    # @example
    #   Gems.yank "gemcutter", "0.2.1", platform: "x86-darwin-10"
    def yank(gem_name, version = nil, platform: nil)
      version ||= latest_version(gem_name)
      delete("/api/v1/gems/yank", {gem_name:, version:, platform:}.compact)
    end

    # Update a previously yanked gem back into RubyGems.org's index
    #
    # @api public
    # @authenticated true
    # @param gem_name [String] The name of a gem.
    # @param version [String, nil] The version of a gem (defaults to the latest version).
    # @param platform [String, nil] The platform of the gem.
    # @return [String]
    # @example
    #   Gems.unyank "gemcutter", "0.2.1", platform: "x86-darwin-10"
    def unyank(gem_name, version = nil, platform: nil)
      version ||= latest_version(gem_name)
      put("/api/v1/gems/unyank", {gem_name:, version:, platform:}.compact)
    end

    # Returns an array of gem version details
    #
    # @api public
    # @authenticated false
    # @param gem_name [String] The name of a gem.
    # @return [Hash]
    # @example
    #   Gems.versions 'coulda'
    def versions(gem_name)
      response = get("/api/v1/versions/#{gem_name}.json")
      JSON.parse(response)
    end

    # Returns an hash of gem latest version
    #
    # @api public
    # @authenticated false
    # @param gem_name [String] The name of a gem.
    # @return [String] the latest version number
    # @example
    #   Gems.latest_version "coulda"
    def latest_version(gem_name)
      response = get("/api/v1/versions/#{gem_name}/latest.json")
      JSON.parse(response).fetch("version")
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
    # @param gem_name [String] The name of a gem.
    # @param version [String, nil] The version of the gem (defaults to the latest version).
    # @return [Hash] with :total_downloads and :version_downloads keys
    # @example
    #   Gems.downloads("rails_admin", "0.0.1")[:version_downloads]
    def downloads(gem_name, version = nil)
      response = get("/api/v1/downloads/#{gem_name}-#{version || latest_version(gem_name)}.json")
      JSON.parse(response, symbolize_names: true)
    end

    # Returns an array containing the top 50 downloaded gem versions of all time
    #
    # @api public
    # @authenticated false
    # @return [Array]
    # @example
    #   Gems.most_downloaded
    def most_downloaded
      response = get("/api/v1/downloads/all.json")
      JSON.parse(response).fetch("gems")
    end

    # View all owners of a gem that you own
    #
    # @api public
    # @authenticated true
    # @param gem_name [String] The name of a gem.
    # @return [Array]
    # @example
    #   Gems.owners 'gemcutter'
    def owners(gem_name)
      response = get("/api/v1/gems/#{gem_name}/owners.json")
      JSON.parse(response)
    end

    # Add an owner to a RubyGem you own, giving that user permission to manage it
    #
    # @api public
    # @authenticated true
    # @param gem_name [String] The name of a gem.
    # @param owner [String] The email address of the user you want to add.
    # @return [String]
    # @example
    #   Gems.add_owner 'gemcutter', 'josh@technicalpickles.com'
    def add_owner(gem_name, owner)
      post("/api/v1/gems/#{gem_name}/owners", {email: owner})
    end

    # Remove a user's permission to manage a RubyGem you own
    #
    # @api public
    # @authenticated true
    # @param gem_name [String] The name of a gem.
    # @param owner [String] The email address of the user you want to remove.
    # @return [String]
    # @example
    #   Gems.remove_owner 'gemcutter', 'josh@technicalpickles.com'
    def remove_owner(gem_name, owner)
      delete("/api/v1/gems/#{gem_name}/owners", {email: owner})
    end

    # List the webhooks registered under your account
    #
    # @api public
    # @authenticated true
    # @return [Hash]
    # @example
    #   Gems.web_hooks
    def web_hooks
      response = get("/api/v1/web_hooks.json")
      JSON.parse(response)
    end

    # Create a webhook
    #
    # @api public
    # @authenticated true
    # @param gem_name [String] The name of a gem. Specify "*" to add the hook to all gems.
    # @param url [String] The URL of the web hook.
    # @return [String]
    # @example
    #   Gems.add_web_hook 'rails', 'http://example.com'
    def add_web_hook(gem_name, url)
      post("/api/v1/web_hooks", {gem_name:, url:})
    end

    # Remove a webhook
    #
    # @api public
    # @authenticated true
    # @param gem_name [String] The name of a gem. Specify "*" to remove the hook from all gems.
    # @param url [String] The URL of the web hook.
    # @return [String]
    # @example
    #   Gems.remove_web_hook 'rails', 'http://example.com'
    def remove_web_hook(gem_name, url)
      delete("/api/v1/web_hooks/remove", {gem_name:, url:})
    end

    # Test fire a webhook
    #
    # @api public
    # @authenticated true
    # @param gem_name [String] The name of a gem. Specify "*" to fire the hook for all gems.
    # @param url [String] The URL of the web hook.
    # @return [String]
    # @example
    #   Gems.fire_web_hook 'rails', 'http://example.com'
    def fire_web_hook(gem_name, url)
      post("/api/v1/web_hooks/fire", {gem_name:, url:})
    end

    # Returns the 50 gems most recently added to RubyGems.org (for the first time)
    #
    # @api public
    # @authenticated false
    # @param page [Integer, nil] The page of results to return.
    # @return [Array]
    # @example
    #   Gems.latest
    def latest(page: nil)
      response = get("/api/v1/activity/latest.json", {page:}.compact)
      JSON.parse(response)
    end

    # Returns the 50 most recently updated gems
    #
    # @api public
    # @authenticated false
    # @param page [Integer, nil] The page of results to return.
    # @return [Array]
    # @example
    #   Gems.just_updated
    def just_updated(page: nil)
      response = get("/api/v1/activity/just_updated.json", {page:}.compact)
      JSON.parse(response)
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
    # @return [String] the new API key
    # @example
    #   Gems.configure do |config|
    #     config.username = "nick@gemcutter.org"
    #     config.password = "schwwwwing"
    #   end
    #   Gems.create_api_key "ci-push", push_rubygem: true
    def create_api_key(name, **scopes)
      JSON.parse(post("/api/v1/api_key.json", {**scopes, name:})).fetch("rubygems_api_key")
    end

    # Update the scopes of an API key using HTTP basic auth
    #
    # @api public
    # @authenticated true
    # @param key [String] The API key to update.
    # @param scopes [Hash{Symbol => Boolean}] Scopes to enable or disable, such as push_rubygem or yank_rubygem.
    # @return [String]
    # @example
    #   Gems.update_api_key "701243f217cdf23b1370c7b66b65ca97", yank_rubygem: true
    def update_api_key(key, **scopes)
      patch("/api/v1/api_key", {**scopes, api_key: key})
    end

    # Exchange an OIDC ID token for an API key via trusted publishing
    #
    # @api public
    # @authenticated false
    # @param id_token [String] The OIDC ID token.
    # @return [Hash] the token exchange response, including rubygems_api_key, name, scopes, and expires_at
    # @example
    #   Gems.exchange_trusted_publisher_token ENV.fetch("ID_TOKEN")
    def exchange_trusted_publisher_token(id_token)
      TrustedPublisherAuthenticator.new(id_token:, host:, connection:, request_builder:).exchange_token!
    end

    # Returns an array of all the reverse dependencies to the given gem
    #
    # @api public
    # @authenticated false
    # @param gem_name [String] The name of a gem
    # @param only [String, nil] Restrict the results to "development" or "runtime" dependencies.
    # @return [Array]
    # @example
    #   Gems.reverse_dependencies "money", only: "runtime"
    def reverse_dependencies(gem_name, only: nil)
      response = get("/api/v1/gems/#{gem_name}/reverse_dependencies.json", {only:}.compact)
      JSON.parse(response)
    end

    # Returns information about the given gem for a specific version
    #
    # @api public
    # @authenticated false
    # @param gem_name [String] The name of a gem.
    # @param version [String] The requested version of the gem.
    # @return [Hash]
    # @example
    #   Gems.version 'rails', '7.0.6'
    def version(gem_name, version)
      response = get("/api/v2/rubygems/#{gem_name}/versions/#{version}.json")
      JSON.parse(response)
    rescue JSON::ParserError
      {}
    end
  end
end
