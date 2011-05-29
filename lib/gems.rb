require 'gems/client'

module Gems
  # Alias for Gems::Client.new
  #
  # @return [Gems::Client]
  def self.new
    Gems::Client.new
  end

  # Delegate to Gems::Client
  def self.method_missing(method, *args, &block)
    return super unless new.respond_to?(method)
    new.send(method, *args, &block)
  end

  def self.respond_to?(method, include_private=false)
    new.respond_to?(method, include_private) || super(method, include_private)
  end
end
