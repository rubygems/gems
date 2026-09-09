module Gems
  # Delegates module-level calls to a client instance
  module AbstractClient
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Class-level delegation methods
    module ClassMethods
      def new(*)
        raise NotImplementedError
      end

      # Delegate to Gems::Client
      def method_missing(method, ...)
        new.public_send(method, ...)
      end

      def respond_to_missing?(method_name, include_private = false)
        new.respond_to?(method_name, include_private)
      end
    end
  end
end
