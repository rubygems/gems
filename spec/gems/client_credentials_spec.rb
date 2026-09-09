RSpec.describe Gems::ClientCredentials do
  let(:client) { Gems::Client.new(key: nil, username: nil, password: nil) }

  describe "#initialize_authenticator" do
    it "uses no authentication without credentials" do
      expect(client.authenticator).to be_an_instance_of(Gems::Authenticator)
    end

    it "uses API key authentication with a key" do
      client = Gems::Client.new(key: TEST_KEY, username: nil, password: nil)

      expect(client.authenticator).to be_an_instance_of(Gems::ApiKeyAuthenticator)
    end

    it "uses basic authentication with a username and password" do
      client = Gems::Client.new(key: nil, username: TEST_USERNAME, password: TEST_PASSWORD)

      expect(client.authenticator).to be_an_instance_of(Gems::BasicAuthenticator)
    end

    it "prefers basic authentication over API key authentication" do
      client = Gems::Client.new(key: TEST_KEY, username: TEST_USERNAME, password: TEST_PASSWORD)

      expect(client.authenticator).to be_an_instance_of(Gems::BasicAuthenticator)
    end

    it "returns the authenticator" do
      expect(client.send(:initialize_authenticator)).to equal(client.authenticator)
    end
  end

  describe "#basic_authenticator" do
    it "returns nil with only a username" do
      client = Gems::Client.new(key: nil, username: TEST_USERNAME, password: nil)

      expect(client.authenticator).to be_an_instance_of(Gems::Authenticator)
    end

    it "returns nil with only a password" do
      client = Gems::Client.new(key: nil, username: nil, password: TEST_PASSWORD)

      expect(client.authenticator).to be_an_instance_of(Gems::Authenticator)
    end

    it "builds an authenticator with the username and password" do
      client = Gems::Client.new(key: nil, username: TEST_USERNAME, password: TEST_PASSWORD)

      expect([client.authenticator.username, client.authenticator.password]).to eq([TEST_USERNAME, TEST_PASSWORD])
    end
  end

  describe "#api_key_authenticator" do
    it "returns nil without a key" do
      expect(client.authenticator).to be_an_instance_of(Gems::Authenticator)
    end

    it "builds an authenticator with the key" do
      client = Gems::Client.new(key: TEST_KEY, username: nil, password: nil)

      expect(client.authenticator.key).to eq(TEST_KEY)
    end
  end

  describe "#key=" do
    it "sets the key" do
      client.key = TEST_KEY

      expect(client.key).to eq(TEST_KEY)
    end

    it "reinitializes the authenticator" do
      client.key = TEST_KEY

      expect(client.authenticator).to be_an_instance_of(Gems::ApiKeyAuthenticator)
    end

    it "removes authentication when cleared" do
      client = Gems::Client.new(key: TEST_KEY, username: nil, password: nil)
      client.key = nil

      expect(client.authenticator).to be_an_instance_of(Gems::Authenticator)
    end
  end

  describe "#username=" do
    before { client.password = TEST_PASSWORD }

    it "sets the username" do
      client.username = TEST_USERNAME

      expect(client.username).to eq(TEST_USERNAME)
    end

    it "reinitializes the authenticator" do
      client.username = TEST_USERNAME

      expect(client.authenticator).to be_an_instance_of(Gems::BasicAuthenticator)
    end
  end

  describe "#password=" do
    before { client.username = TEST_USERNAME }

    it "sets the password" do
      client.password = TEST_PASSWORD

      expect(client.password).to eq(TEST_PASSWORD)
    end

    it "reinitializes the authenticator" do
      client.password = TEST_PASSWORD

      expect(client.authenticator).to be_an_instance_of(Gems::BasicAuthenticator)
    end
  end
end
