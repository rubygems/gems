module Gems
  class Version
    MAJOR = 0 unless defined? Gems::Version::MAJOR
    MINOR = 8 unless defined? Gems::Version::MINOR
    PATCH = 3 unless defined? Gems::Version::PATCH
    PRE = nil unless defined? Gems::Version::PRE

    class << self
      # @return [String]
      def to_s
        [MAJOR, MINOR, PATCH, PRE].compact.join('.')
      end
    end
  end

  VERSION = Version.to_s
end
