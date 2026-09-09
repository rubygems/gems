module Gems
  # Delegates module-level calls to a client instance
  module AbstractClient
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Class-level delegation methods
    module ClassMethods
      def new(_options = {})
        raise NotImplementedError
      end

      # Delegate to Gems::Client
      def method_missing(method, ...)
        return super unless new.respond_to?(method) # steep:ignore UnexpectedSuper

        new.send(method, ...)
      end

      def respond_to?(method_name, include_private = false) # rubocop:disable Style/OptionalBooleanParameter
        new.respond_to?(method_name, include_private) || super # steep:ignore UnexpectedSuper
      end

      def respond_to_missing?(method_name, include_private = false)
        new.respond_to?(method_name, include_private) || super # steep:ignore UnexpectedSuper
      end
    end
  end
end
