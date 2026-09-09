RSpec.describe Gems::Configuration do
  describe "::VALID_OPTIONS_KEYS" do
    it "lists the configurable options" do
      keys = %i[debug_output host id_token key max_redirects open_timeout otp password proxy_url read_timeout]
      keys += %i[user_agent username write_timeout]

      expect(described_class::VALID_OPTIONS_KEYS).to eq(keys)
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
        config.debug_output = $stderr
        config.host = "http://example.com"
        config.id_token = "ID_TOKEN"
        config.key = TEST_KEY
        config.max_redirects = 3
        config.open_timeout = 10
        config.otp = "123456"
        config.password = TEST_PASSWORD
        config.proxy_url = "http://proxy.example.com:8080"
        config.read_timeout = 20
        config.user_agent = "Custom User Agent"
        config.username = TEST_USERNAME
        config.write_timeout = 30
      end
    end

    it "returns a hash of all options" do
      expect(Gems.options).to eq(debug_output: $stderr, host: "http://example.com", id_token: "ID_TOKEN", key: TEST_KEY,
        max_redirects: 3, open_timeout: 10, otp: "123456", password: TEST_PASSWORD, proxy_url: "http://proxy.example.com:8080",
        read_timeout: 20, user_agent: "Custom User Agent", username: TEST_USERNAME, write_timeout: 30)
    end
  end

  describe "#reset" do
    before do
      Gems.configure do |config|
        config.debug_output = $stderr
        config.host = "http://example.com"
        config.id_token = "ID_TOKEN"
        config.key = TEST_KEY
        config.max_redirects = 3
        config.open_timeout = 10
        config.otp = "123456"
        config.password = TEST_PASSWORD
        config.proxy_url = "http://proxy.example.com:8080"
        config.read_timeout = 20
        config.user_agent = "Custom User Agent"
        config.username = TEST_USERNAME
        config.write_timeout = 30
      end
    end

    {
      host: Gems::Configuration::DEFAULT_HOST,
      id_token: nil,
      key: Gems::Configuration::DEFAULT_KEY,
      otp: nil,
      password: nil,
      user_agent: Gems::Configuration::DEFAULT_USER_AGENT,
      username: nil,
      open_timeout: Gems::Connection::DEFAULT_OPEN_TIMEOUT,
      read_timeout: Gems::Connection::DEFAULT_READ_TIMEOUT,
      write_timeout: Gems::Connection::DEFAULT_WRITE_TIMEOUT,
      debug_output: nil,
      proxy_url: nil,
      max_redirects: Gems::RedirectHandler::DEFAULT_MAX_REDIRECTS
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
