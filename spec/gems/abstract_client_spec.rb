describe Gems::AbstractClient do
  it "raises NotImplementedError if new isn't overritten" do
    foo_client = Class.new do
      include Gems::AbstractClient
    end

    expect { foo_client.new }.to raise_error(NotImplementedError)
  end
end
