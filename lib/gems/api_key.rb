require_relative "resource"

module Gems
  # An API key, as returned by the API key and trusted publishing endpoints
  # @api public
  class ApiKey < Resource
    inspect_with :name, :scopes

    # @!method name
    #   The name of the API key
    #   @api public
    #   @return [String, nil] the name of the API key
    #   @example
    #     api_key.name
    attribute :name

    # @!method scopes
    #   The scopes of the API key
    #   @api public
    #   @return [Array<String>, nil] the scopes of the API key
    #   @example
    #     api_key.scopes
    attribute :scopes

    # @!method expires_at
    #   When the API key expires
    #   @api public
    #   @return [Time, nil] when the API key expires
    #   @example
    #     api_key.expires_at
    time_attribute :expires_at

    # The API key
    #
    # @api public
    # @return [String] the API key
    # @raise [KeyError] if the response has no key
    # @example Get the key
    #   api_key.key
    def key
      attributes.fetch("rubygems_api_key")
    end
  end
end
