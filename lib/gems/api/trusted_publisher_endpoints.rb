# frozen_string_literal: true

require "json"
require_relative "../identifiers"
require_relative "../json_parsing"
require_relative "../path_escaping"
require_relative "../request_builder"
require_relative "../trusted_publisher"

module Gems
  module API
    # The trusted publisher endpoints, which configure the workflows that may push a gem without an API key
    #
    # These endpoints need an API key with the `configure_trusted_publishers` scope (see {APIKey::SCOPES}), and a
    # one-time passcode when the account requires multi-factor authentication.
    #
    # @api public
    module TrustedPublisherEndpoints
      include Identifiers
      include JSONParsing
      include PathEscaping

      # List the trusted publishers configured for a gem
      #
      # @api public
      # @authenticated true
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @return [Array<TrustedPublisher>]
      # @example
      #   Gems.trusted_publishers("gems").map(&:name)
      def trusted_publishers(gem_name)
        TrustedPublisher.list(parse_json(get(trusted_publishers_path(gem_name))))
      end

      # Return one of the trusted publishers configured for a gem
      #
      # @api public
      # @authenticated true
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @param trusted_publisher [Integer, String, TrustedPublisher] The ID of a trusted publisher, or one.
      # @return [TrustedPublisher]
      # @example
      #   Gems.trusted_publisher("gems", 1).workflow_filename
      def trusted_publisher(gem_name, trusted_publisher)
        TrustedPublisher.new(parse_json(get(trusted_publisher_path(gem_name, trusted_publisher))))
      end

      # Trust a GitHub Actions workflow to publish a gem
      #
      # The workflow may then push the gem with an OIDC ID token, without an API key (see
      # {APIKeyEndpoints#exchange_trusted_publisher_token} and the `id_token` option of {Client#initialize}).
      #
      # Leave the workflow repository out when the workflow lives in the repository it publishes, and name it when
      # the gem is published by a reusable workflow that lives in another repository.
      #
      # @api public
      # @authenticated true
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @param repository_owner [String] The owner of the repository the workflow runs in.
      # @param repository_name [String] The name of the repository the workflow runs in.
      # @param workflow_filename [String] The filename of the workflow, such as "push_gem.yml".
      # @param environment [String, nil] The GitHub Actions environment the workflow must run in, or nil for any.
      # @param workflow_repository_owner [String, nil] The owner of the repository a reusable workflow lives in.
      # @param workflow_repository_name [String, nil] The name of the repository a reusable workflow lives in.
      # @param type [String] The type of the trusted publisher, which defaults to {TrustedPublisher::GITHUB_ACTION}.
      # @return [TrustedPublisher] the trusted publisher that was added
      # @example
      #   Gems.add_trusted_publisher("gems", repository_owner: "rubygems", repository_name: "gems",
      #     workflow_filename: "push_gem.yml")
      # @example
      #   Gems.add_trusted_publisher("gems", repository_owner: "rubygems", repository_name: "gems",
      #     workflow_filename: "push_gem.yml", environment: "release")
      def add_trusted_publisher(gem_name, repository_owner:, repository_name:, workflow_filename:, environment: nil,
        workflow_repository_owner: nil, workflow_repository_name: nil, type: TrustedPublisher::GITHUB_ACTION)
        publisher = {repository_owner:, repository_name:, workflow_filename:, environment:,
                     workflow_repository_owner:, workflow_repository_name:}.compact
        body = JSON.generate({trusted_publisher_type: type, trusted_publisher: publisher})
        response = post(trusted_publishers_path(gem_name), body, content_type: RequestBuilder::APPLICATION_JSON)
        TrustedPublisher.new(parse_json(response))
      end

      # Stop trusting a publisher to publish a gem
      #
      # @api public
      # @authenticated true
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @param trusted_publisher [Integer, String, TrustedPublisher] The ID of the trusted publisher, or one.
      # @return [String] the body the endpoint answers with, which RubyGems.org leaves empty; a removal that fails
      #   raises instead
      # @example
      #   Gems.remove_trusted_publisher("gems", Gems.trusted_publishers("gems").first)
      def remove_trusted_publisher(gem_name, trusted_publisher)
        delete(trusted_publisher_path(gem_name, trusted_publisher))
      end

      private

      # The path of the trusted publishers of a gem
      # @api private
      # @param gem_name [String, Gem, Version] the name of a gem, or a gem or version
      # @return [String] the path
      def trusted_publishers_path(gem_name)
        "/api/v1/gems/#{escape(name_of(gem_name))}/trusted_publishers"
      end

      # The path of one trusted publisher of a gem
      # @api private
      # @param gem_name [String, Gem, Version] the name of a gem, or a gem or version
      # @param trusted_publisher [Integer, String, TrustedPublisher] the ID of a trusted publisher, or one
      # @return [String] the path
      def trusted_publisher_path(gem_name, trusted_publisher)
        "#{trusted_publishers_path(gem_name)}/#{escape(id_of(trusted_publisher))}"
      end
    end
  end
end
