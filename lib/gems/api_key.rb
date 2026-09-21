# frozen_string_literal: true

require "json"
require_relative "errors/invalid_response"
require_relative "resource"

module Gems
  # An API key, as returned by the API key and trusted publishing endpoints
  # @api public
  class APIKey < Resource
    # The scopes the RubyGems API defines for an API key
    #
    # A scope the API does not define is refused by {API::APIKeyEndpoints#create_api_key} and
    # {API::APIKeyEndpoints#update_api_key} rather than sent, so this is the list a caller building its own scopes
    # can check against.
    #
    # @api public
    SCOPES = %i[
      access_webhooks
      add_owner
      configure_trusted_publishers
      index_rubygems
      push_rubygem
      remove_owner
      show_dashboard
      update_owner
      yank_rubygem
    ].freeze

    inspect_with :name, :scopes
    identified_by :name

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
    # The reader is declared, as the readers of the other attributes are, so that a pattern matches an API key by
    # its key as it matches the rest, such as `in {name:, key:}`. The key is still left out of {#inspect}, so that
    # printing an API key in a console does not print the key it carries.
    #
    # A response that carries no key raises here, rather than answering with nil, since a caller asking for the key
    # is asking for the one thing the endpoint was called for. A pattern is answered without it instead of raising
    # (see {Resource#deconstruct_keys}).
    #
    # @api public
    # @return [String] the API key
    # @raise [InvalidResponse] if the response has no key
    # @example Get the key
    #   api_key.key
    def key
      attributes.fetch("rubygems_api_key") do
        raise InvalidResponse.new(body: JSON.generate(attributes), message: "The API key response has no rubygems_api_key")
      end
    end
    record_attribute(:key)
  end
end
