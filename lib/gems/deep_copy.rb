# frozen_string_literal: true

module Gems
  # The copies a {Resource} is made of and answers with: frozen for the resource, and unfrozen for the caller
  # @api private
  module DeepCopy
    private

    # Copy a value, freezing the copy and everything nested inside it
    #
    # The keys of hashes are converted to strings. Everything a parsed JSON response holds other than hashes, arrays, and strings is already immutable.
    #
    # @api private
    # @param value [Object] the value to copy
    # @return [Object] the frozen copy
    def deep_freeze(value)
      case value
      when Hash then value.to_h { |key, nested| [key.to_s, deep_freeze(nested)] }.freeze
      when Array then value.map { |nested| deep_freeze(nested) }.freeze
      when String then value.dup.freeze
      else value
      end
    end

    # Copy a value and everything nested inside it, for the caller to change
    #
    # The keys of hashes are left as they are, since a hash freezes the strings it is keyed by itself. Everything a
    # parsed JSON response holds other than hashes, arrays, and strings answers `dup` with itself.
    #
    # @api private
    # @param value [Object] the value to copy
    # @return [Object] the copy, which is not frozen
    def deep_dup(value)
      case value
      when Hash then value.transform_values { |nested| deep_dup(nested) }
      when Array then value.map { |nested| deep_dup(nested) }
      else value.dup
      end
    end
  end
end
