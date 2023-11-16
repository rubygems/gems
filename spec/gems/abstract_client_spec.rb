require 'helper'

describe Gems::AbstractClient do
  it "raises NotImplementedError if new isn't overritten" do
    FooClient = Class.new do
      include Gems::AbstractClient
    end

    expect { FooClient.new }.to raise_error(NotImplementedError)
  end
end
