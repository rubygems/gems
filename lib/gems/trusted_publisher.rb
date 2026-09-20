# frozen_string_literal: true

require_relative "resource"

module Gems
  # A trusted publisher of a gem, which may push it without an API key of its own
  #
  # The endpoints wrap the publisher in the record that ties it to the gem, so the readers of the publisher itself,
  # such as {#repository_owner}, read the object nested under it, and {#publisher} is that object as it was sent.
  #
  # @api public
  class TrustedPublisher < Resource
    # The type of a trusted publisher that is a GitHub Actions workflow, the only type the RubyGems API defines
    #
    # {API::TrustedPublisherEndpoints#add_trusted_publisher} sends this type unless it is given another, so that a
    # type the API adds can be configured before this library knows about it.
    #
    # @api public
    GITHUB_ACTION = "OIDC::TrustedPublisher::GitHubAction"

    inspect_with :id, :name
    identified_by :id

    # Define a reader for an attribute of the publisher nested in the record
    #
    # @api private
    # @param name [Symbol] the name of the reader, which is the key it reads
    # @return [Symbol] the name of the reader
    def self.publisher_attribute(name)
      key = name.to_s
      define_method(name) do
        # @type self: TrustedPublisher
        publisher[key]
      end
      record_attribute(name)
    end

    # @!method id
    #   The ID of the trusted publisher
    #
    #   The endpoints that read and remove one identify it by this ID.
    #   @api public
    #   @return [Integer, nil] the ID of the trusted publisher
    #   @example
    #     trusted_publisher.id
    attribute :id

    # @!method type
    #   The type of the trusted publisher, such as {GITHUB_ACTION}
    #   @api public
    #   @return [String, nil] the type of the trusted publisher
    #   @example
    #     trusted_publisher.type
    attribute :type, "trusted_publisher_type"

    # @!method name
    #   The name of the trusted publisher
    #
    #   Such as "GitHub Actions rubygems/gems @ .github/workflows/push.yml".
    #   @api public
    #   @return [String, nil] the name of the trusted publisher
    #   @example
    #     trusted_publisher.name
    publisher_attribute :name

    # @!method repository_owner
    #   The owner of the repository the workflow runs in
    #   @api public
    #   @return [String, nil] the owner of the repository
    #   @example
    #     trusted_publisher.repository_owner
    publisher_attribute :repository_owner

    # @!method repository_owner_id
    #   The ID GitHub gives the owner of the repository, which a renamed owner keeps
    #   @api public
    #   @return [String, nil] the ID of the owner of the repository
    #   @example
    #     trusted_publisher.repository_owner_id
    publisher_attribute :repository_owner_id

    # @!method repository_name
    #   The name of the repository the workflow runs in
    #   @api public
    #   @return [String, nil] the name of the repository
    #   @example
    #     trusted_publisher.repository_name
    publisher_attribute :repository_name

    # @!method workflow_filename
    #   The filename of the workflow, such as "push_gem.yml"
    #   @api public
    #   @return [String, nil] the filename of the workflow
    #   @example
    #     trusted_publisher.workflow_filename
    publisher_attribute :workflow_filename

    # @!method environment
    #   The GitHub Actions environment the workflow must run in
    #
    #   Nil when the workflow may run in any environment.
    #   @api public
    #   @return [String, nil] the environment of the workflow
    #   @example
    #     trusted_publisher.environment
    publisher_attribute :environment

    # @!method workflow_repository_owner
    #   The owner of the repository a reusable workflow lives in
    #
    #   Nil when the workflow lives in the repository it publishes.
    #   @api public
    #   @return [String, nil] the owner of the repository of a reusable workflow
    #   @example
    #     trusted_publisher.workflow_repository_owner
    publisher_attribute :workflow_repository_owner

    # @!method workflow_repository_name
    #   The name of the repository a reusable workflow lives in
    #
    #   Nil when the workflow lives in the repository it publishes.
    #   @api public
    #   @return [String, nil] the name of the repository of a reusable workflow
    #   @example
    #     trusted_publisher.workflow_repository_name
    publisher_attribute :workflow_repository_name

    # The attributes of the publisher itself, as the endpoint sent them
    #
    # The readers of this class read the fields of a GitHub Actions workflow, which is the only type the RubyGems
    # API defines; this is the object they read, for a type that has fields of its own.
    #
    # @api public
    # @return [Hash{String => Object}] the attributes of the publisher, empty when the record carries none
    # @example Read a field of a publisher type this library has no reader for
    #   trusted_publisher.publisher["repository_owner"]
    def publisher
      self["trusted_publisher"] || {}
    end
  end
end
