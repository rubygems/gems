require "time"
require_relative "errors/invalid_response"

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
    # Endpoints spell some fields differently, so a reader may declare several keys and reads the first
    # one the response contains.
    #
    # @api private
    # @param name [Symbol] the name of the reader
    # @param keys [Array<String, Symbol>] the attribute keys, most preferred first (defaults to the name)
    # @return [Symbol] the name of the reader
    def self.attribute(name, *keys)
      keys = keys_for(name, keys)
      define_method(name) do
        # @type self: Resource
        value_of(keys)
      end
      record_attribute(name)
    end

    # Define a predicate for a boolean attribute
    #
    # @api private
    # @param name [Symbol] the name of the attribute (the reader is suffixed with a question mark)
    # @param keys [Array<String, Symbol>] the attribute keys, most preferred first (defaults to the name)
    # @return [Symbol] the name of the reader
    def self.predicate(name, *keys)
      keys = keys_for(name, keys)
      define_method(:"#{name}?") do
        # @type self: Resource
        !!value_of(keys)
      end
      record_attribute(:"#{name}?")
    end

    # Define a reader that parses a timestamp attribute
    #
    # The reader raises {InvalidResponse} when the attribute is not a timestamp.
    #
    # @api private
    # @param name [Symbol] the name of the reader
    # @param keys [Array<String, Symbol>] the attribute keys, most preferred first (defaults to the name)
    # @return [Symbol] the name of the reader
    def self.time_attribute(name, *keys)
      keys = keys_for(name, keys)
      define_method(name) do
        # @type self: Resource
        value = value_of(keys)
        value && parse_time(value)
      end
      record_attribute(name)
    end

    # The names of the readers the class declares
    #
    # These are the readers declared with attribute, predicate, and time_attribute, and a pattern matches a resource
    # by these names (see {#deconstruct_keys}).
    #
    # @api public
    # @return [Array<Symbol>] the reader names, in the order they were declared
    # @example
    #   Gems::Owner.attribute_names # => [:id, :handle, :email, :role]
    def self.attribute_names
      @attribute_names || []
    end

    # Record a declared reader for {.attribute_names}
    #
    # @api private
    # @param name [Symbol] the name of the reader
    # @return [Symbol] the name of the reader
    def self.record_attribute(name)
      @attribute_names = [*attribute_names, name]
      name
    end
    private_class_method :record_attribute

    # The attribute keys a reader reads
    #
    # @api private
    # @param name [Symbol] the name of the reader
    # @param keys [Array<String, Symbol>] the declared keys
    # @return [Array<String>] the keys, most preferred first
    def self.keys_for(name, keys)
      keys = [name] if keys.empty?
      keys.map(&:to_s)
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

    # Declare which readers identify the resource
    #
    # Resources with an identity compare equal when those readers match, even if other attributes differ.
    #
    # @api private
    # @param readers [Array<Symbol>] the identifying readers
    # @return [Array<Symbol>] the identifying readers
    def self.identified_by(*readers)
      @identity_readers = readers
    end

    # The readers that identify the resource
    #
    # @api private
    # @return [Array<Symbol>] the identifying readers, empty when the resource is identified by all of its attributes
    def self.identity_readers
      @identity_readers || []
    end

    # Initialize a new resource
    #
    # The attributes are deeply copied and frozen, so resources are immutable values and the hash passed in
    # stays mutable.
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

    # The attributes a pattern asks for, read by the declared readers
    #
    # A resource matches a `case`/`in` pattern by the names in {.attribute_names}, read as the readers read them, so
    # a pattern sees a timestamp as a `Time` and a boolean as a predicate such as `yanked?`.
    #
    # @api public
    # @param keys [Array<Symbol>, nil] the names the pattern asks for, or nil for all of them
    # @return [Hash{Symbol => Object}] the requested attributes
    # @example Match a gem by its name and version
    #   case Gems.rubygem("rails")
    #   in {name: "rails", version:} then version
    #   end
    def deconstruct_keys(keys)
      names = self.class.attribute_names
      names &= keys unless keys.nil?
      names.to_h { |name| [name, public_send(name)] }
    end

    # The values that identify the resource
    #
    # @api public
    # @return [Array<Object>, Hash{String => Object}] the identifying values, or all attributes when no identity is declared
    # @example Get a gem's identity
    #   gem.identity # => ["rails"]
    def identity
      readers = self.class.identity_readers
      readers.empty? ? attributes : readers.map { |reader| public_send(reader) }
    end

    # Compare with another resource
    #
    # @api public
    # @param other [Object] the object to compare with
    # @return [Boolean] true if the other object is the same kind of resource with the same identity
    # @example Compare two gems
    #   Gems.rubygem("rails") == Gems.rubygem("rails") # => true
    def ==(other)
      other.instance_of?(self.class) && identity == other.identity
    end

    # Compare with another resource for use as a hash key
    #
    # Unlike {#==}, identity values are compared with `eql?`, so this agrees with {#hash}.
    #
    # @api public
    # @param other [Object] the object to compare with
    # @return [Boolean] true if the other object is the same kind of resource with an eql? identity
    # @example Compare two gems strictly
    #   Gems.rubygem("rails").eql?(Gems.rubygem("rails")) # => true
    def eql?(other)
      other.instance_of?(self.class) && identity.eql?(other.identity)
    end

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
      [self.class, identity].hash
    end

    private

    # The value of the first of the given keys the response contains
    # @api private
    # @param keys [Array<String>] the attribute keys, most preferred first
    # @return [Object, nil] the value, or nil when the response contains none of the keys
    def value_of(keys)
      keys.each { |key| return self[key] if attributes.key?(key) }
      nil
    end

    # Parse a timestamp attribute
    # @api private
    # @param value [Object] the attribute value
    # @return [Time] the parsed time
    # @raise [InvalidResponse] if the value is not a timestamp
    def parse_time(value)
      Time.parse(value)
    rescue ArgumentError, TypeError
      raise InvalidResponse.new(body: value.to_s, message: "#{value.inspect} is not a timestamp")
    end

    # Copy a value, freezing the copy and everything nested inside it
    #
    # Everything a parsed JSON response holds other than hashes, arrays, and strings is already immutable.
    #
    # @api private
    # @param value [Object] the value to copy
    # @return [Object] the frozen copy
    def deep_freeze(value)
      case value
      when Hash then value.to_h { |key, nested| [key, deep_freeze(nested)] }.freeze
      when Array then value.map { |nested| deep_freeze(nested) }.freeze
      when String then value.dup.freeze
      else value
      end
    end
  end
end
