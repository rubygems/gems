module Gems
  # Delegates module-level calls to a client instance
  module AbstractClient
    # Extend the including module with the delegation methods
    #
    # @api private
    # @param base [Module] the including module
    # @return [void]
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Class-level delegation methods
    # @api public
    module ClassMethods
      # Build a client to delegate to
      #
      # @api public
      # @raise [NotImplementedError] unless the including module overrides this method
      # @return [Object] a client
      # @example Delegate to Gems::Client
      #   def self.new(options = {}) = Gems::Client.new(options)
      def new(*)
        raise NotImplementedError
      end

      # Delegate a method call to a new client
      #
      # @api private
      # @param method [Symbol] the method name
      # @return [Object] the client's return value
      # @raise [NoMethodError] if the client does not respond to the method
      def method_missing(method, ...)
        new.public_send(method, ...)
      end

      # Check whether a new client responds to a method
      #
      # @api private
      # @param method_name [Symbol] the method name
      # @param include_private [Boolean] whether to include private methods
      # @return [Boolean] true if the client responds to the method
      def respond_to_missing?(method_name, include_private = false)
        new.respond_to?(method_name, include_private)
      end
    end
  end
end
