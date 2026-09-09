RSpec.describe Gems::ApiKeyAuthenticator do
  subject(:authenticator) { described_class.new(key: TEST_KEY) }

  it "is an Authenticator" do
    expect(authenticator).to be_a(Gems::Authenticator)
  end

  describe "#initialize" do
    it "sets the key" do
      expect(authenticator.key).to eq(TEST_KEY)
    end
  end

  describe "#header" do
    it "returns an Authorization header with the key" do
      expect(authenticator.header(Net::HTTP::Get.new("/"))).to eq("Authorization" => TEST_KEY)
    end
  end

  describe "#inspect" do
    it "shows the class without the key" do
      expect(authenticator.inspect).to eq("#<Gems::ApiKeyAuthenticator>")
    end
  end
end
