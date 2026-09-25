# frozen_string_literal: true

require "rubygems"

module Gems
  # Shows the build a resource names in its summary, included in {Gem} and {Version}
  #
  # A gem or version is identified by its platform and the Ruby ABI it was built for as well as by its number (see
  # {Resource#==}), so {Resource#inspect} shows them where they tell one build from another: the platform unless it
  # is "ruby", which almost every version is built for, and the Ruby ABI when there is one.
  #
  # @api private
  module BuildSummary
    private

    # The readers {Resource#inspect} shows, with the platform and Ruby ABI
    #
    # The platform is shown unless it is "ruby", and the Ruby ABI when there is one.
    #
    # @api private
    # @return [Hash{Symbol => Object}] the value of each reader shown, in the order they are shown
    def inspect_values
      values = super
      values[:platform] = platform unless platform.nil? || platform.eql?(::Gem::Platform::RUBY)
      values[:ruby_abi] = ruby_abi unless ruby_abi.nil?
      values
    end
  end
end
