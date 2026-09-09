RSpec.describe Gems::BaseClient do
  subject(:client) { described_class.new(key: nil, username: nil, password: nil) }

  describe "#initialize" do
    {
      debug_output: $stderr,
      host: "http://example.com",
      id_token: "ID_TOKEN",
      key: TEST_KEY,
      max_redirects: 3,
      open_timeout: 10,
      otp: "123456",
      password: TEST_PASSWORD,
      proxy_url: "http://proxy.example.com:8080",
      read_timeout: 20,
      user_agent: "Custom User Agent",
      username: TEST_USERNAME,
      write_timeout: 30
    }.each do |key, value|
      it "defaults the #{key} to the global configuration" do
        Gems.public_send(:"#{key}=", value)

        expect(described_class.new.public_send(key)).to eq(value)
      end

      it "sets the #{key} from the options" do
        expect(described_class.new(key => value).public_send(key)).to eq(value)
      end
    end

    it "configures every option" do
      expect(Gems::Configuration::VALID_OPTIONS_KEYS.map { |key| described_class.new.respond_to?(key) }).to all(be(true))
    end

    it "ignores unknown options" do
      expect { described_class.new(unknown: true) }.not_to raise_error
    end

    it "initializes the authenticator from the credentials" do
      expect(described_class.new(key: TEST_KEY, username: nil, password: nil).authenticator)
        .to be_an_instance_of(Gems::ApiKeyAuthenticator)
    end
  end

  describe "#user_agent=" do
    it "sets the user agent" do
      client.user_agent = "Custom User Agent"

      expect(client.user_agent).to eq("Custom User Agent")
    end

    it "updates an existing request builder" do
      builder = client.request_builder
      client.user_agent = "Custom User Agent"

      expect(builder.user_agent).to eq("Custom User Agent")
    end
  end

  %i[open_timeout read_timeout write_timeout debug_output].each do |option|
    describe "##{option}=" do
      it "sets the #{option} on the connection" do
        client.public_send(:"#{option}=", 42)

        expect(client.connection.public_send(option)).to eq(42)
      end
    end

    describe "##{option}" do
      it "reads the #{option} from the connection" do
        client.connection.public_send(:"#{option}=", 42)

        expect(client.public_send(option)).to eq(42)
      end
    end
  end

  describe "#proxy_url=" do
    it "sets the proxy URL on the connection" do
      client.proxy_url = "http://proxy.example.com:8080"

      expect(client.connection.proxy_url).to eq("http://proxy.example.com:8080")
    end

    it "ignores nil" do
      client.proxy_url = "http://proxy.example.com:8080"
      client.proxy_url = nil

      expect(client.proxy_url).to eq("http://proxy.example.com:8080")
    end
  end

  describe "#proxy_url" do
    it "reads the proxy URL from the connection" do
      client.connection.proxy_url = "http://proxy.example.com:8080"

      expect(client.proxy_url).to eq("http://proxy.example.com:8080")
    end
  end

  describe "#max_redirects=" do
    it "sets the maximum redirects on the redirect handler" do
      client.max_redirects = 3

      expect(client.redirect_handler.max_redirects).to eq(3)
    end
  end

  describe "#max_redirects" do
    it "reads the maximum redirects from the redirect handler" do
      client.redirect_handler.max_redirects = 3

      expect(client.max_redirects).to eq(3)
    end
  end

  describe "#inspect" do
    it "shows the host and authenticator without credentials" do
      client = described_class.new(host: "http://example.com", key: TEST_KEY, username: nil, password: nil)

      expect(client.inspect).to eq('#<Gems::BaseClient host="http://example.com" authenticator=#<Gems::ApiKeyAuthenticator>>')
    end
  end

  describe "#host=" do
    it "sets the host" do
      client.host = "http://example.com"

      expect(client.host).to eq("http://example.com")
    end

    it "reinitializes the authenticator with the new host" do
      client.id_token = "ID_TOKEN"
      client.host = "http://example.com"

      expect(client.authenticator.host).to eq("http://example.com")
    end
  end
end
