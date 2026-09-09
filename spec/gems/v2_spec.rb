RSpec.describe Gems::V2 do
  describe ".new" do
    it "returns a Gems::V2::Client" do
      expect(described_class.new).to be_an_instance_of(Gems::V2::Client)
    end

    it "passes options to the client" do
      client = described_class.new(key: TEST_KEY, host: "http://example.com")

      expect([client.key, client.host]).to eq([TEST_KEY, "http://example.com"])
    end
  end

  describe ".info" do
    before { stub_get("/api/v2/rubygems/rails/versions/7.0.6.json").to_return(body: fixture("v2/rails-7.0.6.json")) }

    it "delegates to a client" do
      expect(described_class.info("rails", "7.0.6")).to eq(Gems::V2::Client.new.info("rails", "7.0.6"))
    end
  end
end
