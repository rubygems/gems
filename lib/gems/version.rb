module Gems
  # The version of the Gems gem
  class Version
    MAJOR = 2 unless defined? Gems::Version::MAJOR
    MINOR = 0 unless defined? Gems::Version::MINOR
    PATCH = 0 unless defined? Gems::Version::PATCH
    PRE = nil unless defined? Gems::Version::PRE

    class << self
      # The version as a string
      #
      # @api public
      # @return [String] the version string
      # @example Get the version string
      #   Gems::Version.to_s
      def to_s
        [MAJOR, MINOR, PATCH, PRE].compact.join(".")
      end
    end
  end

  VERSION = Version.to_s
end
