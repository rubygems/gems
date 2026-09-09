RSpec.describe Gems::Identifiers do
  let(:client) { Gems::Client.new(key: nil, username: nil, password: nil) }

  describe "#name_of" do
    it "returns a name unchanged" do
      expect(client.send(:name_of, "rails")).to eq("rails")
    end

    it "returns the name of a gem" do
      expect(client.send(:name_of, Gems::Gem.new("name" => "rails"))).to eq("rails")
    end

    it "returns the name of a version" do
      expect(client.send(:name_of, Gems::Version.new("name" => "rails"))).to eq("rails")
    end
  end

  describe "#number_of" do
    it "returns a number unchanged" do
      expect(client.send(:number_of, "7.0.6")).to eq("7.0.6")
    end

    it "returns nil unchanged" do
      expect(client.send(:number_of, nil)).to be_nil
    end

    it "returns the number of a version" do
      expect(client.send(:number_of, Gems::Version.new("number" => "7.0.6"))).to eq("7.0.6")
    end
  end

  describe "#handle_of" do
    it "returns a handle unchanged" do
      expect(client.send(:handle_of, "sferik")).to eq("sferik")
    end

    it "returns the handle of an owner" do
      expect(client.send(:handle_of, Gems::Owner.new("handle" => "sferik", "email" => "sferik@gmail.com"))).to eq("sferik")
    end

    it "falls back to the email of an owner without a handle" do
      expect(client.send(:handle_of, Gems::Owner.new("email" => "sferik@gmail.com"))).to eq("sferik@gmail.com")
    end
  end

  describe "#url_of" do
    it "returns a URL unchanged" do
      expect(client.send(:url_of, "http://example.com")).to eq("http://example.com")
    end

    it "returns the URL of a web hook" do
      expect(client.send(:url_of, Gems::WebHook.new("url" => "http://example.com"))).to eq("http://example.com")
    end
  end

  describe "#key_of" do
    it "returns a key unchanged" do
      expect(client.send(:key_of, TEST_KEY)).to eq(TEST_KEY)
    end

    it "returns the key of an API key" do
      expect(client.send(:key_of, Gems::ApiKey.new("rubygems_api_key" => TEST_KEY))).to eq(TEST_KEY)
    end

    it "returns nil for nil" do
      expect(client.send(:key_of, nil)).to be_nil
    end
  end
end
