RSpec.describe Gems::BaseClient do
  subject(:client) { described_class.new(key: nil, username: nil, password: nil) }

  describe "#initialize" do
    Gems::Configuration::VALID_OPTIONS_KEYS.each do |key|
      it "defaults the #{key} to the global configuration" do
        Gems.public_send(:"#{key}=", "configured #{key}")

        expect(described_class.new.public_send(key)).to eq("configured #{key}")
      end

      it "sets the #{key} from the options" do
        expect(described_class.new(key => "custom #{key}").public_send(key)).to eq("custom #{key}")
      end
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

  describe "#host=" do
    it "sets the host" do
      client.host = "http://example.com"

      expect(client.host).to eq("http://example.com")
    end
  end
end
