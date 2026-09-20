RSpec.describe Gems::Configuration do
  describe "::DEFAULT_HOST" do
    it "defaults to rubygems.org" do
      expect(described_class::DEFAULT_HOST).to eq("https://rubygems.org")
    end
  end

  describe "#default_host" do
    # Set RUBYGEMS_HOST for the block, restoring it before the configuration is reset between examples
    def with_gem_host(host)
      original = ENV.fetch("RUBYGEMS_HOST", nil)
      ENV["RUBYGEMS_HOST"] = host
      yield
    ensure
      ENV["RUBYGEMS_HOST"] = original
    end

    it "defaults to rubygems.org" do
      expect(Gems.default_host).to eq("https://rubygems.org")
    end

    it "reads the RUBYGEMS_HOST environment variable" do
      with_gem_host("https://gems.example.com") { expect(Gems.default_host).to eq("https://gems.example.com") }
    end

    it "reads the environment when it is called, not when the library is required" do
      with_gem_host("https://gems.example.com") { Gems.reset }

      expect(Gems.host).to eq("https://gems.example.com")
    end
  end

  describe "#key_configured?" do
    it "is false until a key is assigned" do
      expect(Gems.key_configured?).to be(false)
    end

    it "is true once a key is assigned" do
      Gems.key = TEST_KEY

      expect(Gems.key_configured?).to be(true)
    end

    it "is true once a key is assigned nil" do
      Gems.key = nil

      expect(Gems.key_configured?).to be(true)
    end

    it "is false again after a reset" do
      Gems.key = TEST_KEY
      Gems.reset

      expect(Gems.key_configured?).to be(false)
    end
  end

  describe "#default_key" do
    let(:api_keys) { {:rubygems_api_key => "FILE_KEY", "https://gems.example.com" => "HOST_KEY"} }

    before { allow(Gem).to receive(:configuration).and_return(instance_double(Gem::ConfigFile, rubygems_api_key: "FILE_KEY", api_keys:)) }

    it "reads the RubyGems.org API key from the RubyGems configuration" do
      expect(Gems.default_key).to eq("FILE_KEY")
    end

    it "reads the API key stored for the configured host" do
      Gems.host = "https://gems.example.com"

      expect(Gems.default_key).to eq("HOST_KEY")
    end

    it "falls back to the RubyGems.org API key for a host without one" do
      Gems.host = "https://other.example.com"

      expect(Gems.default_key).to eq("FILE_KEY")
    end

    it "reads the API key stored for a given host" do
      expect(Gems.default_key("https://gems.example.com")).to eq("HOST_KEY")
    end

    it "falls back to the RubyGems.org API key for a given host without one" do
      expect(Gems.default_key("https://other.example.com")).to eq("FILE_KEY")
    end

    it "prefers the GEM_HOST_API_KEY environment variable" do
      stub_const("ENV", ENV.to_h.merge("GEM_HOST_API_KEY" => "ENV_KEY"))
      Gems.host = "https://gems.example.com"

      expect(Gems.default_key).to eq("ENV_KEY")
    end

    it "does not read the RubyGems configuration when GEM_HOST_API_KEY is set" do
      stub_const("ENV", ENV.to_h.merge("GEM_HOST_API_KEY" => "ENV_KEY"))
      Gems.default_key

      expect(Gem).not_to have_received(:configuration)
    end

    it "returns nil without a stored key" do
      allow(Gem).to receive(:configuration).and_return(instance_double(Gem::ConfigFile, rubygems_api_key: nil, api_keys: {}))

      expect(Gems.default_key).to be_nil
    end

    it "returns nil when RubyGems refuses to read the credentials file" do
      configuration = instance_double(Gem::ConfigFile)
      allow(configuration).to receive(:api_keys).and_raise(Gem::SystemExitException.new(1))
      allow(Gem).to receive(:configuration).and_return(configuration)

      expect(Gems.default_key).to be_nil
    end
  end

  describe "#key" do
    before { allow(Gem).to receive(:configuration).and_return(instance_double(Gem::ConfigFile, rubygems_api_key: "FILE_KEY", api_keys: {})) }

    it "returns the configured key" do
      Gems.key = TEST_KEY

      expect(Gems.key).to eq(TEST_KEY)
    end

    it "falls back to the default key" do
      expect(Gems.key).to eq("FILE_KEY")
    end

    it "stays unauthenticated after being set to nil" do
      Gems.key = TEST_KEY
      Gems.key = nil

      expect(Gems.key).to be_nil
    end
  end

  describe "#key=" do
    it "resolves the key of an API key object" do
      Gems.key = Gems::APIKey.new("rubygems_api_key" => TEST_KEY)

      expect(Gems.key).to eq(TEST_KEY)
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

      expect([mod.host, mod.instance_variable_get(:@key), mod.user_agent, mod.username])
        .to eq([described_class::DEFAULT_HOST, nil, described_class::DEFAULT_USER_AGENT, nil])
    end
  end

  describe "#configure" do
    it "yields the configuration" do
      expect { |b| Gems.configure(&b) }.to yield_with_args(Gems)
    end

    it "returns the configuration" do
      expect(Gems.configure { nil }).to equal(Gems)
    end

    options = %i[host id_token key otp password user_agent username]
    options += %i[open_timeout read_timeout write_timeout keep_alive_timeout debug_output proxy_url max_redirects]
    options.each do |key|
      it "sets the #{key}" do
        Gems.configure { |config| config.public_send(:"#{key}=", key.to_s) }

        expect(Gems.public_send(key)).to eq(key.to_s)
      end
    end
  end

  describe "#reset" do
    before do
      Gems.configure do |config|
        config.host = "http://example.com"
        config.id_token = "ID_TOKEN"
        config.key = TEST_KEY
        config.otp = "123456"
        config.password = TEST_PASSWORD
        config.user_agent = "Custom User Agent"
        config.username = TEST_USERNAME
        config.open_timeout = 10
        config.read_timeout = 20
        config.write_timeout = 30
        config.keep_alive_timeout = 40
        config.debug_output = $stderr
        config.proxy_url = "http://proxy.example.com:8080"
        config.max_redirects = 3
      end
    end

    {
      host: Gems::Configuration::DEFAULT_HOST,
      id_token: nil,
      otp: nil,
      password: nil,
      user_agent: Gems::Configuration::DEFAULT_USER_AGENT,
      username: nil,
      open_timeout: Gems::Connection::DEFAULT_OPEN_TIMEOUT,
      read_timeout: Gems::Connection::DEFAULT_READ_TIMEOUT,
      write_timeout: Gems::Connection::DEFAULT_WRITE_TIMEOUT,
      keep_alive_timeout: Gems::Connection::DEFAULT_KEEP_ALIVE_TIMEOUT,
      debug_output: nil,
      proxy_url: nil,
      max_redirects: Gems::RedirectHandler::DEFAULT_MAX_REDIRECTS
    }.each do |option, default|
      it "resets the #{option} to its default" do
        Gems.reset

        expect(Gems.public_send(option)).to eq(default)
      end
    end

    it "restores the default key" do
      allow(Gem).to receive(:configuration).and_return(instance_double(Gem::ConfigFile, rubygems_api_key: "FILE_KEY", api_keys: {}))
      Gems.key = TEST_KEY
      Gems.reset

      expect(Gems.key).to eq("FILE_KEY")
    end

    it "returns the configuration" do
      expect(Gems.reset).to equal(Gems)
    end
  end
end
