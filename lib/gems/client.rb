require 'date'
require 'gems/configuration'
require 'gems/connection'
require 'gems/request'

module Gems
  class Client
    include Gems::Connection
    include Gems::Request
    attr_accessor *Configuration::VALID_OPTIONS_KEYS

    def initialize(options={})
      options = Gems.options.merge(options)
      Configuration::VALID_OPTIONS_KEYS.each do |key|
        send("#{key}=", options[key])
      end
    end

    # Returns some basic information about the given gem
    #
    # @param gem_name [String] The name of a gem.
    # @return [Hash]
    # @example
    #   Gems.info 'rails'
    def info(gem_name)
      response = get("/api/v1/gems/#{gem_name}")
      format.to_s.downcase == 'xml' ? response['rubygem'] : response
    end

    # Returns an array of active gems that match the query
    #
    # @param query [String] A term to search for.
    # @return [Array<Hash>]
    # @example
    #   Gems.search 'cucumber'
    def search(query)
      response = get("/api/v1/search", {:query => query})
      format.to_s.downcase == 'xml' ? response['rubygems'] : response
    end

    # Returns an array of gem version details
    #
    # @param gem_name [String] The name of a gem.
    # @return [Hash]
    # @example
    #   Gems.versions 'coulda'
    def versions(gem_name)
      get("/api/v1/versions/#{gem_name}", {}, :json)
    end

    # Returns the number of downloads by day for a particular gem version
    #
    # @param gem_name [String] The name of a gem.
    # @param gem_version [String] The version of a gem.
    # @param from [Date] Search start date.
    # @param to [Date] Search end date.
    # @return [Hash]
    # @example
    #   Gems.downloads 'coulda', '0.6.3', Date.today - 30, Date.today
    def downloads(gem_name, gem_version=nil, from=nil, to=Date.today)
      gem_version ||= info(gem_name)['version']
      if from
        get("/api/v1/versions/#{gem_name}-#{gem_version}/downloads/search", {:from => from.to_s, :to => to.to_s}, :json)
      else
        get("/api/v1/versions/#{gem_name}-#{gem_version}/downloads", {}, :json)
      end
    end

    # Returns an array of hashes for all versions of given gems
    #
    # @param gems [Array] A list of gem names
    # @return [Array]
    # @example
    #   Gems.dependencies 'rails', 'thor'
    def dependencies(*gems)
      get('/api/v1/dependencies', {:gems => gems.join(',')}, :marshal)
    end

    # Retrieve your API key using HTTP basic auth
    #
    # @return [String]
    # @example
    #   Gems.configure do |config|
    #     config.username = 'nick@gemcutter.org'
    #     config.password = 'schwwwwing'
    #   end
    #   Gems.api_key
    def api_key
      get('/api/v1/api_key', {}, :raw)
    end

    # List all gems that you own
    #
    # @return [Array]
    # @example
    #   Gems.gems
    def gems
      response = get("/api/v1/gems")
      format.to_s.downcase == 'xml' ? response['rubygems'] : response
    end

    # View all owners of a gem that you own
    #
    # @param gem_name [String] The name of a gem.
    # @return [Array]
    # @example
    #   Gems.owners 'gemcutter'
    def owners(gem_name)
      get("/api/v1/gems/#{gem_name}/owners")
    end

    # Add an owner to a RubyGem you own, giving that user permission to manage it
    #
    # @param gem_name [String] The name of a gem.
    # @param owner [String] The email address of the user you want to add.
    # @return [String]
    # @example
    #   Gems.add_owner 'gemcutter', 'josh@technicalpickles.com'
    def add_owner(gem_name, owner)
      post("/api/v1/gems/#{gem_name}/owners", {:email => owner}, :raw)
    end

    # Remove a user's permission to manage a RubyGem you own
    #
    # @param gem_name [String] The name of a gem.
    # @param owner [String] The email address of the user you want to remove.
    # @return [String]
    # @example
    #   Gems.remove_owner 'gemcutter', 'josh@technicalpickles.com'
    def remove_owner(gem_name, owner)
      delete("/api/v1/gems/#{gem_name}/owners", {:email => owner}, :raw)
    end

    # List the webhooks registered under your account
    #
    # @return [Hash]
    # @example
    #   Gems.web_hooks
    def web_hooks
      get("/api/v1/web_hooks", {}, :json)
    end

    # Create a webhook
    #
    # @param gem_name [String] The name of a gem. Specify "*" to add the hook to all your gems.
    # @param url [String] The URL of the web hook.
    # @return [String]
    # @example
    #   Gems.add_web_hook 'rails', 'http://example.com'
    def add_web_hook(gem_name, url)
      post("/api/v1/web_hooks", {:gem_name => gem_name, :url => url}, :raw)
    end

    # Remove a webhook
    #
    # @param gem_name [String] The name of a gem. Specify "*" to remove the hook from all your gems.
    # @param url [String] The URL of the web hook.
    # @return [String]
    # @example
    #   Gems.remove_web_hook 'rails', 'http://example.com'
    def remove_web_hook(gem_name, url)
      delete("/api/v1/web_hooks/remove", {:gem_name => gem_name, :url => url}, :raw)
    end

    # Test fire a webhook
    #
    # @param gem_name [String] The name of a gem. Specify "*" to fire the hook for all your gems.
    # @param url [String] The URL of the web hook.
    # @return [String]
    # @example
    #   Gems.fire_web_hook 'rails', 'http://example.com'
    def fire_web_hook(gem_name, url)
      post("/api/v1/web_hooks/fire", {:gem_name => gem_name, :url => url}, :raw)
    end

    # Submit a gem to RubyGems.org
    #
    # @param gem [File] A built gem.
    # @return [String]
    # @example
    #   Gems.push File.new 'pkg/gemcutter-0.2.1.gem', 'rb'
    def push(gem)
      post("/api/v1/gems", gem.read, :raw, 'application/octet-stream')
    end

    # Remove a gem from RubyGems.org's index
    #
    # @param gem_name [String] The name of a gem.
    # @param gem_version [String] The version of a gem.
    # @param options [Hash] A customizable set of options.
    # @option options [String] :platform
    # @return [String]
    # @example
    #   Gems.yank "gemcutter", "0.2.1", {:platform => "x86-darwin-10"}
    def yank(gem_name, gem_version=nil, options={})
      gem_version ||= info(gem_name)['version']
      delete("/api/v1/gems/yank", options.merge(:gem_name => gem_name, :version => gem_version), :raw)
    end

    # Update a previously yanked gem back into RubyGems.org's index
    #
    # @param gem_name [String] The name of a gem.
    # @param gem_version [String] The version of a gem.
    # @param options [Hash] A customizable set of options.
    # @option options [String] :platform
    # @return [String]
    # @example
    #   Gems.unyank "gemcutter", "0.2.1", {:platform => "x86-darwin-10"}
    def unyank(gem_name, gem_version=nil, options={})
      gem_version ||= info(gem_name)['version']
      put("/api/v1/gems/unyank", options.merge(:gem_name => gem_name, :version => gem_version), :raw)
    end
  end
end
