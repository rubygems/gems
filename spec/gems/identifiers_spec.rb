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

    it "returns nil for nil" do
      expect(client.send(:name_of, nil)).to be_nil
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

  describe "#platform_of" do
    it "returns nil for a version number" do
      expect(client.send(:platform_of, "7.0.6")).to be_nil
    end

    it "returns the platform of a version" do
      expect(client.send(:platform_of, Gems::Version.new("number" => "1.15.0", "platform" => "java"))).to eq("java")
    end
  end

  describe "#full_name_of" do
    it "joins the name and number" do
      expect(client.send(:full_name_of, "rails", "7.0.6", nil)).to eq("rails-7.0.6")
    end

    it "appends the platform" do
      expect(client.send(:full_name_of, "nokogiri", "1.15.0", "java")).to eq("nokogiri-1.15.0-java")
    end

    it "omits the ruby platform" do
      expect(client.send(:full_name_of, "rails", "7.0.6", "ruby")).to eq("rails-7.0.6")
    end

    it "defaults to the platform of a version" do
      version = Gems::Version.new("name" => "nokogiri", "number" => "1.15.0", "platform" => "java")

      expect(client.send(:full_name_of, version, version, nil)).to eq("nokogiri-1.15.0-java")
    end

    it "prefers an explicit platform" do
      version = Gems::Version.new("number" => "1.15.0", "platform" => "java")

      expect(client.send(:full_name_of, "nokogiri", version, "x86_64-linux")).to eq("nokogiri-1.15.0-x86_64-linux")
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

    it "returns the handle of a profile" do
      expect(client.send(:handle_of, Gems::Profile.new("id" => 1, "handle" => "sferik"))).to eq("sferik")
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
