require "time"

module Gems
  # Base class for objects that wrap RubyGems API responses
  # @api public
  class Resource
    # The raw attributes from the API response
    # @api public
    # @return [Hash{String => Object}] the raw attributes
    # @example Get the raw attributes
    #   gem.attributes["name"]
    attr_reader :attributes

    # Build a list of resources from a list of attribute hashes
    #
    # @api public
    # @param list [Array<Hash>] the attribute hashes
    # @return [Array<Resource>] the resources
    # @example Build a list of gems
    #   Gems::Gem.list(JSON.parse(body))
    def self.list(list)
      list.map { |attributes| new(attributes) } #: Array[instance]
    end

    # Define a reader for an attribute
    #
    # @api private
    # @param name [Symbol] the name of the reader
    # @param key [String, Symbol] the attribute key
    # @return [Symbol] the name of the reader
    def self.attribute(name, key = name)
      define_method(name) do
        # @type self: Resource
        self[key]
      end
    end

    # Define a predicate for a boolean attribute
    #
    # @api private
    # @param name [Symbol] the name of the attribute (the reader is suffixed with a question mark)
    # @param key [String, Symbol] the attribute key
    # @return [Symbol] the name of the reader
    def self.predicate(name, key = name)
      define_method(:"#{name}?") do
        # @type self: Resource
        !!self[key]
      end
    end

    # Define a reader that parses a timestamp attribute
    #
    # @api private
    # @param name [Symbol] the name of the reader
    # @param key [String, Symbol] the attribute key
    # @return [Symbol] the name of the reader
    def self.time_attribute(name, key = name)
      define_method(name) do
        # @type self: Resource
        value = self[key]
        value && Time.parse(value)
      end
    end

    # Declare which readers appear in the inspect output
    #
    # @api private
    # @param readers [Array<Symbol>] the readers to show
    # @return [Array<Symbol>] the readers to show
    def self.inspect_with(*readers)
      @inspect_readers = readers
    end

    # The readers shown in the inspect output
    #
    # @api private
    # @return [Array<Symbol>] the readers to show
    def self.inspect_readers
      @inspect_readers || []
    end

    # Initialize a new resource
    #
    # The attributes, including nested hashes, arrays, and strings, are frozen, so resources are immutable values.
    #
    # @api public
    # @param attributes [Hash{String => Object}] the raw attributes from the API response
    # @return [Resource] a new instance
    # @example Wrap a parsed response
    #   Gems::Gem.new(JSON.parse(body))
    def initialize(attributes)
      @attributes = deep_freeze(attributes)
    end

    # Read a raw attribute
    #
    # @api public
    # @param key [String, Symbol] the attribute key
    # @return [Object, nil] the attribute value
    # @example Read an attribute that has no reader
    #   gem[:dependencies]
    def [](key)
      attributes[key.to_s]
    end

    # Convert the resource to a hash
    #
    # @api public
    # @return [Hash{String => Object}] the raw attributes
    # @example Convert a gem to a hash
    #   gem.to_h
    def to_h
      attributes
    end

    # Compare with another resource
    #
    # @api public
    # @param other [Object] the object to compare with
    # @return [Boolean] true if the other object is the same kind of resource with the same attributes
    # @example Compare two gems
    #   gem == other_gem
    def ==(other)
      other.instance_of?(self.class) && attributes == other.attributes
    end
    alias_method :eql?, :==

    # Summarize the resource for the console
    #
    # Only the readers declared with {.inspect_with} are shown, so the output stays short and never includes secrets.
    #
    # @api public
    # @return [String] the summary
    # @example Inspect a gem
    #   gem.inspect # => #<Gems::Gem name="rails" version="8.1.2">
    def inspect
      fields = self.class.inspect_readers.map { |reader| " #{reader}=#{public_send(reader).inspect}" }
      "#<#{self.class}#{fields.join}>"
    end

    # Generate a hash code for the resource
    #
    # @api public
    # @return [Integer] the hash code
    # @example Use resources as hash keys
    #   {gem => true}
    def hash
      [self.class, attributes].hash
    end

    private

    # Freeze a value and everything nested inside it
    # @api private
    # @param value [Object] the value to freeze
    # @return [Object] the frozen value
    def deep_freeze(value)
      case value
      when Hash then value.each_value { |nested| deep_freeze(nested) }
      when Array then value.each { |nested| deep_freeze(nested) }
      end
      value.freeze
    end
  end
end
