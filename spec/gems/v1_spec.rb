RSpec.describe Gems::V1 do
  describe ".new" do
    it "returns a Gems::V1::Client" do
      expect(described_class.new).to be_an_instance_of(Gems::V1::Client)
    end

    it "passes options to the client" do
      client = described_class.new(key: TEST_KEY, host: "http://example.com")

      expect([client.key, client.host]).to eq([TEST_KEY, "http://example.com"])
    end
  end

  describe ".info" do
    before { stub_get("/api/v1/gems/rails.json").to_return(body: fixture("rails.json")) }

    it "delegates to a client" do
      expect(described_class.info("rails")).to eq(Gems::V1::Client.new.info("rails"))
    end
  end
end
