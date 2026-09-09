RSpec.describe Gems::Configuration do
  describe "::VALID_OPTIONS_KEYS" do
    it "lists the configurable options" do
      expect(described_class::VALID_OPTIONS_KEYS).to eq(%i[host key password user_agent username])
    end
  end

  describe "::DEFAULT_HOST" do
    it "defaults to rubygems.org" do
      expect(described_class::DEFAULT_HOST).to eq("https://rubygems.org")
    end
  end

  describe "::DEFAULT_KEY" do
    it "is loaded from the RubyGems configuration" do
      expect(described_class::DEFAULT_KEY).to eq(Gem.configuration.rubygems_api_key)
    end
  end

  describe "::DEFAULT_USER_AGENT" do
    it "includes the version" do
      expect(described_class::DEFAULT_USER_AGENT).to eq("Gems #{Gems::VERSION}")
    end
  end

  describe ".extended" do
    it "resets the configuration of the extending module" do
      mod = Module.new.extend(described_class)

      expect(mod.options).to eq(Gems.reset.options)
    end
  end

  describe "#configure" do
    it "yields the configuration" do
      expect { |b| Gems.configure(&b) }.to yield_with_args(Gems)
    end

    it "returns the configuration" do
      expect(Gems.configure { nil }).to equal(Gems)
    end

    described_class::VALID_OPTIONS_KEYS.each do |key|
      it "sets the #{key}" do
        Gems.configure { |config| config.public_send(:"#{key}=", key.to_s) }

        expect(Gems.public_send(key)).to eq(key.to_s)
      end
    end
  end

  describe "#options" do
    before do
      Gems.configure do |config|
        config.host = "http://example.com"
        config.key = TEST_KEY
        config.password = TEST_PASSWORD
        config.user_agent = "Custom User Agent"
        config.username = TEST_USERNAME
      end
    end

    it "returns a hash of all options" do
      expect(Gems.options).to eq(host: "http://example.com", key: TEST_KEY, password: TEST_PASSWORD,
        user_agent: "Custom User Agent", username: TEST_USERNAME)
    end
  end

  describe "#reset" do
    before do
      Gems.configure do |config|
        config.host = "http://example.com"
        config.key = TEST_KEY
        config.password = TEST_PASSWORD
        config.user_agent = "Custom User Agent"
        config.username = TEST_USERNAME
      end
    end

    {
      host: Gems::Configuration::DEFAULT_HOST,
      key: Gems::Configuration::DEFAULT_KEY,
      password: nil,
      user_agent: Gems::Configuration::DEFAULT_USER_AGENT,
      username: nil
    }.each do |option, default|
      it "resets the #{option} to its default" do
        Gems.reset

        expect(Gems.public_send(option)).to eq(default)
      end
    end

    it "resets the key to the stored default key" do
      stub_const("Gems::Configuration::DEFAULT_KEY", "FILE_KEY")
      Gems.reset

      expect(Gems.key).to eq("FILE_KEY")
    end

    it "returns the configuration" do
      expect(Gems.reset).to equal(Gems)
    end
  end
end
