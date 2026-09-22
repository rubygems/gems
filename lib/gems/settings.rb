# frozen_string_literal: true

module Gems
  # Declares the settings that are a number of seconds or a number of times, and checks what is assigned to them,
  # mixed into the configuration, the connection, the redirect handler, and the retry handler
  #
  # A number is checked where it is assigned, as a host, a proxy URL, and the paths of certificates are (see
  # {URLValidation} and {CertificateOptions}), so that the error names the assignment that was wrong rather than
  # the request that later waits for a negative number of seconds, or compares the times it has been sent again
  # with a String. The value that is rejected is left as it was.
  #
  # The settings are declared rather than written out, as the readers of a {Resource} are, since the reader and the
  # writer of each differ only in the name they carry and the check the writer makes; each is documented where it
  # is declared.
  #
  # @api private
  module Settings
    # The macros that declare the settings, extended into whatever includes {Settings}
    # @api private
    module Declaration
      # Declare a setting that is a number of seconds
      #
      # @api private
      # @param name [Symbol] the name of the setting
      # @return [Symbol] the name of the writer
      # @example Declare a timeout
      #   seconds_setting :open_timeout
      def seconds_setting(name)
        attr_reader(name)

        define_method(:"#{name}=") do |seconds|
          # @type self: Settings
          instance_variable_set(:"@#{name}", validate_number(name, seconds))
        end
      end

      # Declare a setting that is a number of times
      #
      # @api private
      # @param name [Symbol] the name of the setting
      # @return [Symbol] the name of the writer
      # @example Declare a maximum
      #   count_setting :max_retries
      def count_setting(name)
        attr_reader(name)

        define_method(:"#{name}=") do |count|
          # @type self: Settings
          instance_variable_set(:"@#{name}", validate_count(name, count))
        end
      end
    end

    # Extend whatever includes the mixin with the macros that declare the settings
    #
    # @api private
    # @param base [Module] the module or class including {Settings}
    # @return [void]
    def self.included(base)
      base.extend(Declaration)
    end

    private

    # Check that a setting is a number of zero or more
    #
    # Any Numeric is one, since a timeout shorter than a second is a Float, and zero is one: it turns off the wait
    # or the retrying the setting names rather than leaving it unset.
    #
    # @api private
    # @param name [Symbol] the name of the setting, which the message names
    # @param number [Object] the value assigned
    # @return [Numeric] the number
    # @raise [ArgumentError] if the value is not a number of zero or more
    def validate_number(name, number)
      raise ArgumentError, "Invalid #{name}: #{number.inspect}" unless number.is_a?(Numeric) && number >= 0

      number
    end

    # Check that a setting is a whole number of times
    #
    # @api private
    # @param name [Symbol] the name of the setting, which the message names
    # @param count [Object] the value assigned
    # @return [Integer] the count
    # @raise [ArgumentError] if the value is not a whole number of zero or more times
    def validate_count(name, count)
      raise ArgumentError, "Invalid #{name}: #{count.inspect}" unless validate_number(name, count).integer?

      count
    end
  end
end
