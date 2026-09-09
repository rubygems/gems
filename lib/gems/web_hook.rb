require_relative "resource"

module Gems
  # A web hook registered for a gem
  # @api public
  class WebHook < Resource
    inspect_with :gem_name, :url

    # @!method gem_name
    #   The name of the gem the web hook is registered for, or "*" for all gems
    #   @api public
    #   @return [String, nil] the name of the gem
    #   @example
    #     web_hook.gem_name
    attribute :gem_name

    # @!method url
    #   The URL of the web hook
    #   @api public
    #   @return [String, nil] the URL of the web hook
    #   @example
    #     web_hook.url
    attribute :url

    # @!method failure_count
    #   The number of times the web hook has failed
    #   @api public
    #   @return [Integer, nil] the number of times the web hook has failed
    #   @example
    #     web_hook.failure_count
    attribute :failure_count
  end
end
