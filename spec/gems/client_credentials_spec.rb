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

    it "uses trusted publisher authentication with an ID token" do
      client = Gems::Client.new(key: nil, username: nil, password: nil, id_token: "ID_TOKEN")

      expect(client.authenticator).to be_an_instance_of(Gems::TrustedPublisherAuthenticator)
    end

    it "prefers trusted publisher authentication over API key authentication" do
      client = Gems::Client.new(key: TEST_KEY, username: nil, password: nil, id_token: "ID_TOKEN")

      expect(client.authenticator).to be_an_instance_of(Gems::TrustedPublisherAuthenticator)
    end

    it "prefers basic authentication over trusted publisher authentication" do
      client = Gems::Client.new(key: nil, username: TEST_USERNAME, password: TEST_PASSWORD, id_token: "ID_TOKEN")

      expect(client.authenticator).to be_an_instance_of(Gems::BasicAuthenticator)
    end

    it "wraps the authenticator with a one-time passcode" do
      client = Gems::Client.new(key: TEST_KEY, username: nil, password: nil, otp: "123456")

      expect(client.authenticator).to be_an_instance_of(Gems::OtpAuthenticator)
    end
  end

  describe "#otp_authenticator" do
    it "returns the authenticator unchanged without a one-time passcode" do
      client = Gems::Client.new(key: TEST_KEY, username: nil, password: nil, otp: nil)

      expect(client.authenticator).to be_an_instance_of(Gems::ApiKeyAuthenticator)
    end

    it "wraps the credential authenticator with the one-time passcode" do
      client = Gems::Client.new(key: TEST_KEY, username: nil, password: nil, otp: "123456")

      expect([client.authenticator.otp, client.authenticator.authenticator.class]).to eq(["123456", Gems::ApiKeyAuthenticator])
    end

    it "sends the one-time passcode with requests" do
      client = Gems::Client.new(key: TEST_KEY, username: nil, password: nil, otp: "123456")
      stub_get("/path")
      client.get("/path")

      expect(a_get("/path").with(headers: {"Authorization" => TEST_KEY, "OTP" => "123456"})).to have_been_made
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

  describe "#trusted_publisher_authenticator" do
    let(:client) { Gems::Client.new(key: nil, username: nil, password: nil, id_token: "ID_TOKEN", host: "http://example.com") }

    it "returns nil without an ID token" do
      client = Gems::Client.new(key: nil, username: nil, password: nil, id_token: nil)

      expect(client.authenticator).to be_an_instance_of(Gems::Authenticator)
    end

    it "builds an authenticator with the ID token" do
      expect(client.authenticator.id_token).to eq("ID_TOKEN")
    end

    it "builds an authenticator with the client's host" do
      expect(client.authenticator.host).to eq("http://example.com")
    end

    it "builds an authenticator with the client's connection" do
      expect(client.authenticator.connection).to equal(client.connection)
    end

    it "builds an authenticator with the client's request builder" do
      expect(client.authenticator.request_builder).to equal(client.request_builder)
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

  describe "#otp=" do
    it "sets the one-time passcode" do
      client.otp = "123456"

      expect(client.otp).to eq("123456")
    end

    it "reinitializes the authenticator" do
      client.otp = "123456"

      expect(client.authenticator).to be_an_instance_of(Gems::OtpAuthenticator)
    end
  end

  describe "#id_token=" do
    it "sets the ID token" do
      client.id_token = "ID_TOKEN"

      expect(client.id_token).to eq("ID_TOKEN")
    end

    it "reinitializes the authenticator" do
      client.id_token = "ID_TOKEN"

      expect(client.authenticator).to be_an_instance_of(Gems::TrustedPublisherAuthenticator)
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
