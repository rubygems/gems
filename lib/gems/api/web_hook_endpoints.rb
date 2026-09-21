# frozen_string_literal: true

require_relative "../identifiers"
require_relative "../json_parsing"
require_relative "../web_hook"

module Gems
  module API
    # The web hook endpoints, which manage notifications for pushed gems
    # @api public
    module WebHookEndpoints
      include Identifiers
      include JSONParsing

      # Mapping of the gem name groupings returned by the web hooks endpoint to the names used to register hooks
      WEB_HOOK_GEM_NAMES = {"all gems" => "*"}.freeze
      private_constant :WEB_HOOK_GEM_NAMES

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
        hooks = parse_json(get("/api/v1/web_hooks.json")) do |json|
          json.flat_map do |gem_name, group|
            group.map { |hook| hook.merge("gem_name" => WEB_HOOK_GEM_NAMES.fetch(gem_name, gem_name)) }
          end
        end
        WebHook.list(hooks)
      end

      # Create a webhook
      #
      # @api public
      # @authenticated true
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version. Specify "*" to add the hook to all gems.
      # @param url [String, WebHook] The URL of the web hook, or a web hook.
      # @return [String] the message the endpoint answers with
      # @example
      #   Gems.add_web_hook "rails", "http://example.com"
      def add_web_hook(gem_name, url)
        post("/api/v1/web_hooks", {gem_name: name_of(gem_name), url: url_of(url)})
      end

      # Remove a webhook
      #
      # @api public
      # @authenticated true
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version. Specify "*" to remove the hook from all gems.
      # @param url [String, WebHook] The URL of the web hook, or a web hook.
      # @return [String] the message the endpoint answers with
      # @example
      #   Gems.remove_web_hook "rails", "http://example.com"
      def remove_web_hook(gem_name, url)
        delete("/api/v1/web_hooks/remove", {gem_name: name_of(gem_name), url: url_of(url)})
      end

      # Test fire a webhook
      #
      # @api public
      # @authenticated true
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version. Specify "*" to fire the hook for all gems.
      # @param url [String, WebHook] The URL of the web hook, or a web hook.
      # @return [String] the message the endpoint answers with
      # @example
      #   Gems.fire_web_hook "rails", "http://example.com"
      def fire_web_hook(gem_name, url)
        post("/api/v1/web_hooks/fire", {gem_name: name_of(gem_name), url: url_of(url)})
      end
    end
  end
end
