RSpec.describe Gems do
  it "extends Gems::Configuration" do
    expect(described_class).to be_a(Gems::Configuration)
  end

  describe "::VERSION" do
    it "is a String" do
      expect(Gems::VERSION).to be_a(String)
    end

    it "is a valid gem version" do
      expect(Gem::Version.correct?(Gems::VERSION)).to be(true)
    end
  end

  describe ".new" do
    it "returns a Gems::Client" do
      expect(described_class.new).to be_an_instance_of(Gems::Client)
    end

    it "passes options to the client" do
      client = described_class.new(key: TEST_KEY, host: "http://example.com", max_redirects: 3)

      expect([client.key, client.host, client.max_redirects]).to eq([TEST_KEY, "http://example.com", 3])
    end
  end

  Gems::API.public_instance_methods(false).each do |method|
    it "delegates .#{method} to a client" do
      expect(described_class).to respond_to(method)
    end
  end

  it "does not respond to undefined methods" do
    expect(described_class).not_to respond_to(:foo)
  end

  describe ".gem" do
    before { stub_get("/api/v1/gems/rails.json").to_return(body: fixture("rails.json")) }

    it "delegates to a client" do
      described_class.gem("rails")

      expect(a_get("/api/v1/gems/rails.json")).to have_been_made
    end

    it "returns the same result as a client" do
      expect(described_class.gem("rails")).to eq(Gems::Client.new.gem("rails"))
    end
  end

  describe ".version" do
    before { stub_get("/api/v2/rubygems/rails/versions/7.0.6.json").to_return(body: fixture("v2/rails-7.0.6.json")) }

    it "delegates to a client" do
      expect(described_class.version("rails", "7.0.6")).to eq(Gems::Client.new.version("rails", "7.0.6"))
    end
  end
end
