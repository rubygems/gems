require "json"
require_relative "../identifiers"
require_relative "../owner"

module Gems
  module API
    # The owner endpoints, which manage who can push a gem
    # @api public
    module OwnerEndpoints
      include Identifiers

      # View all owners of a gem that you own
      #
      # @api public
      # @authenticated true
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @return [Array<Owner>]
      # @example
      #   Gems.owners "gemcutter"
      def owners(gem_name)
        Owner.list(JSON.parse(get("/api/v1/gems/#{name_of(gem_name)}/owners.json")))
      end

      # Add an owner to a RubyGem you own, giving that user permission to manage it
      #
      # @api public
      # @authenticated true
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @param owner [String, Owner] The email address or handle of the user you want to add, or an owner.
      # @param role [String, nil] The role to grant, "owner" or "maintainer"; defaults to "owner".
      # @return [String]
      # @example
      #   Gems.add_owner "gemcutter", "josh@technicalpickles.com"
      # @example
      #   Gems.add_owner "gemcutter", "josh@technicalpickles.com", role: "maintainer"
      def add_owner(gem_name, owner, role: nil)
        post("/api/v1/gems/#{name_of(gem_name)}/owners", {email: handle_of(owner), role:}.compact)
      end

      # Update the role of an existing owner of a RubyGem you own
      #
      # @api public
      # @authenticated true
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @param owner [String, Owner] The email address or handle of the owner, or an owner.
      # @param role [String] The new role, "owner" or "maintainer".
      # @return [String]
      # @example
      #   Gems.update_owner "gemcutter", "josh@technicalpickles.com", role: "maintainer"
      def update_owner(gem_name, owner, role:)
        patch("/api/v1/gems/#{name_of(gem_name)}/owners", {email: handle_of(owner), role:})
      end

      # Remove a user's permission to manage a RubyGem you own
      #
      # @api public
      # @authenticated true
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @param owner [String, Owner] The email address or handle of the user you want to remove, or an owner.
      # @return [String]
      # @example
      #   Gems.remove_owner "gemcutter", "josh@technicalpickles.com"
      def remove_owner(gem_name, owner)
        delete("/api/v1/gems/#{name_of(gem_name)}/owners", {email: handle_of(owner)})
      end
    end
  end
end
