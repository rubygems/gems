# frozen_string_literal: true

require "rubygems"

module Gems
  # Orders the resources that carry the number of a gem version, included in {Gem} and {Version}
  #
  # A resource is ordered by the name of its gem, then by its number as RubyGems orders numbers, and then by its
  # platform, so that the gems and versions of a response sort as `gem list` orders them rather than as the strings
  # they are written with, where "7.0.10" comes before "7.0.9". Each class reads the number from the key its
  # endpoints answer with: {Gem#gem_version} from `version`, and {Version#gem_version} from `number`.
  #
  # `Comparable` is deliberately not included: a resource is equal to another by its identity, whatever fields the
  # endpoint it came from answered with (see {Resource#==}), where `Comparable` would answer that it is equal to
  # whatever it is ordered alongside, such as the same number of another gem.
  #
  # @api public
  module Ordering
    # Compare with another resource of the same kind
    #
    # @api public
    # @param other [Object] the object to compare with
    # @return [Integer, nil] -1, 0, or 1, or nil when the other object is not the same kind of resource, or either
    #   resource carries no number, or one RubyGems cannot read
    # @example Read the latest version of a gem
    #   Gems.versions("rails").max.number
    # @example Order the versions of a gem, oldest first
    #   Gems.versions("rails").sort
    # @example Order the gems a search answered with
    #   Gems.search("cucumber").sort
    def <=>(other)
      return unless other.instance_of?(self.class)

      ordering&.<=>(other.ordering) # steep:ignore NoMethod
    end

    protected

    # The values the resource is ordered by
    #
    # A resource answers with these to the resource it is ordered against, rather than to a caller, as it answers
    # with its identity to the resource it is compared with (see {Resource#identity}). There are none for a
    # resource that carries no number, or one RubyGems cannot read, so that ordering it against another answers
    # with nil rather than with an order the numbers do not give.
    #
    # @api private
    # @return [Array<Object>, nil] the name, number, and platform, or nil when there is no number to order by
    def ordering
      version = gem_version
      [name.to_s, version, platform.to_s] if version
    end

    private

    # Read a version number as the `Gem::Version` RubyGems orders numbers by
    #
    # @api private
    # @param number [Object] the version number, as the response carried it
    # @return [::Gem::Version, nil] the number, or nil when there is none, or one RubyGems cannot read
    def gem_version_of(number)
      ::Gem::Version.new(number) if number.is_a?(String) && ::Gem::Version.correct?(number)
    end
  end
end
