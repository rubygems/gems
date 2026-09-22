# frozen_string_literal: true

require_relative "../identifiers"
require_relative "../json_parsing"
require_relative "../path_escaping"
require_relative "../owner"

module Gems
  module API
    # The owner endpoints, which manage who can push a gem
    # @api public
    module OwnerEndpoints
      include Identifiers
      include JSONParsing
      include PathEscaping

      # View all owners of a gem
      #
      # The endpoint is public: the owners of a gem, including their email addresses, are returned without
      # credentials, as they are on the gem's page.
      #
      # @api public
      # @authenticated false
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @return [Array<Owner>]
      # @example
      #   Gems.owners "gemcutter"
      def owners(gem_name)
        Owner.list(parse_json(get("/api/v1/gems/#{escape(name_of(gem_name))}/owners.json")))
      end

      # Add an owner to a RubyGem you own, giving that user permission to manage it
      #
      # @api public
      # @authenticated true
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @param owner [String, Owner] The email address or handle of the user you want to add, or an owner.
      # @param role [String, Symbol, nil] The role to grant, "owner" or "maintainer", which are the roles
      #   {Owner::ROLES} names; defaults to "owner".
      # @return [String] the message the endpoint answers with
      # @raise [ArgumentError] if the role is not one the API defines
      # @example
      #   Gems.add_owner "gemcutter", "josh@technicalpickles.com"
      # @example
      #   Gems.add_owner "gemcutter", "josh@technicalpickles.com", role: "maintainer"
      def add_owner(gem_name, owner, role: nil)
        validate_role(role)
        post("/api/v1/gems/#{escape(name_of(gem_name))}/owners", {email: handle_of(owner), role:}.compact)
      end

      # Update the role of an existing owner of a RubyGem you own
      #
      # @api public
      # @authenticated true
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @param owner [String, Owner] The email address or handle of the owner, or an owner.
      # @param role [String, Symbol] The new role, "owner" or "maintainer", which are the roles {Owner::ROLES}
      #   names.
      # @return [String] the message the endpoint answers with
      # @raise [ArgumentError] if the role is not one the API defines
      # @example
      #   Gems.update_owner "gemcutter", "josh@technicalpickles.com", role: "maintainer"
      def update_owner(gem_name, owner, role:)
        validate_role(role)
        patch("/api/v1/gems/#{escape(name_of(gem_name))}/owners", {email: handle_of(owner), role:})
      end

      # Remove a user's permission to manage a RubyGem you own
      #
      # @api public
      # @authenticated true
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @param owner [String, Owner] The email address or handle of the user you want to remove, or an owner.
      # @return [String] the message the endpoint answers with
      # @example
      #   Gems.remove_owner "gemcutter", "josh@technicalpickles.com"
      def remove_owner(gem_name, owner)
        delete("/api/v1/gems/#{escape(name_of(gem_name))}/owners", {email: handle_of(owner)})
      end

      private

      # Check that a role is one the RubyGems API defines
      #
      # A role the API does not define is reported here rather than sent, as an API key scope it does not define
      # is, so that a misspelled role names the argument that was wrong rather than whatever the endpoint answers
      # with.
      #
      # @api private
      # @param role [String, Symbol, nil] the role, or nil to leave it to the endpoint
      # @return [void]
      # @raise [ArgumentError] if the role is not one the API defines
      def validate_role(role)
        return if role.nil? || Owner::ROLES.include?(role.to_s)

        raise ArgumentError, "Unknown owner role: #{role}. The roles the API defines are: #{Owner::ROLES.join(", ")}"
      end
    end
  end
end
