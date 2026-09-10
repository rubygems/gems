require "json"
require_relative "../identifiers"
require_relative "../web_hook"

module Gems
  module API
    # The web hook endpoints, which manage notifications for pushed gems
    # @api public
    module WebHookEndpoints
      include Identifiers

      # Mapping of the gem name groupings returned by the web hooks endpoint to the names used to register hooks
      WEB_HOOK_GEM_NAMES = {"all gems" => "*"}.freeze

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
    end
  end
end
