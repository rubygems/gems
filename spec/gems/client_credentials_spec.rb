# frozen_string_literal: true

RSpec.describe Gems::ClientCredentials do
  let(:client) { Gems::Client.new(key: nil, username: nil, password: nil) }

  describe "#initialize_credentials" do
    let(:client) do
      Gems::Client.new(key: TEST_KEY, username: TEST_USERNAME, password: TEST_PASSWORD, otp: "123456", id_token: "ID_TOKEN")
    end

    it "sets the key" do
      expect(client.key).to eq(TEST_KEY)
    end

    it "resolves the key of an API key object" do
      client = Gems::Client.new(key: Gems::APIKey.new("rubygems_api_key" => TEST_KEY))

      expect(client.key).to eq(TEST_KEY)
    end

    it "sets the username" do
      expect(client.username).to eq(TEST_USERNAME)
    end

    it "sets the password" do
      expect(client.password).to eq(TEST_PASSWORD)
    end

    it "sets the one-time passcode" do
      expect(client.otp).to eq("123456")
    end

    it "sets the ID token" do
      expect(client.id_token).to eq("ID_TOKEN")
    end

    it "records a key given to the client as configured" do
      expect(Gems::Client.new(key: TEST_KEY).send(:credentials_configured?)).to be(true)
    end

    it "records a configured key as configured" do
      Gems.key = TEST_KEY

      expect(Gems::Client.new.send(:credentials_configured?)).to be(true)
    end

    it "records no key as not configured" do
      stub_rubygems_configuration

      expect(Gems::Client.new.send(:credentials_configured?)).to be(false)
    end

    it "falls back to the key stored for the host without a key" do
      stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"})

      expect(Gems::Client.new(host: "https://gems.example.com").key).to eq("HOST_KEY")
    end
  end

  describe "#configured_key" do
    it "reads the configured key" do
      Gems.key = TEST_KEY

      expect(Gems::Client.new.send(:configured_key)).to eq(TEST_KEY)
    end

    it "prefers the configured key to the key stored for the host of the client" do
      stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"})
      Gems.key = TEST_KEY

      expect(Gems::Client.new(host: "https://gems.example.com").send(:configured_key)).to eq(TEST_KEY)
    end

    it "reads the key stored for the host of the client without a configured key" do
      stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"})

      expect(Gems::Client.new(host: "https://gems.example.com").send(:configured_key)).to eq("HOST_KEY")
    end

    it "sends no key for a host without a stored key, rather than the RubyGems.org key" do
      stub_rubygems_configuration

      expect(Gems::Client.new(host: "https://gems.example.com").send(:configured_key)).to be_nil
    end

    it "returns nil without a stored key" do
      stub_rubygems_configuration(rubygems_api_key: nil)

      expect(Gems::Client.new(host: "https://gems.example.com").send(:configured_key)).to be_nil
    end
  end

  describe "#authenticator_for" do
    it "authenticates another host with the key stored for it" do
      stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"})

      expect(Gems::Client.new.send(:authenticator_for, "https://gems.example.com"))
        .to have_attributes(class: Gems::APIKeyAuthenticator, key: "HOST_KEY")
    end

    it "does not authenticate another host without a stored key" do
      stub_rubygems_configuration(rubygems_api_key: nil)

      expect(Gems::Client.new.send(:authenticator_for, "https://gems.example.com"))
        .to be_an_instance_of(Gems::Authenticator)
    end

    it "wraps the key stored for another host with the one-time passcode" do
      stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"})

      expect(Gems::Client.new(otp: "123456").send(:authenticator_for, "https://gems.example.com"))
        .to have_attributes(class: Gems::OTPAuthenticator, otp: "123456")
    end

    it "keeps the authenticator of the client for its own host written another way" do
      stub_rubygems_configuration(api_keys: {TEST_HOST => "HOST_KEY"})

      expect(Gems::Client.new.send(:authenticator_for, "https://RubyGems.org:443"))
        .to have_attributes(class: Gems::APIKeyAuthenticator, key: "HOST_KEY")
    end

    it "keeps the authenticator of the client for its own host with a path prefix" do
      stub_rubygems_configuration(api_keys: {TEST_HOST => "HOST_KEY"})

      expect(Gems::Client.new.send(:authenticator_for, "#{TEST_HOST}/gems"))
        .to have_attributes(class: Gems::APIKeyAuthenticator, key: "HOST_KEY")
    end

    it "authenticates a host that differs only in port with the key stored for it" do
      stub_rubygems_configuration(api_keys: {"https://rubygems.org:8443" => "OTHER_KEY", TEST_HOST => "HOST_KEY"})

      expect(Gems::Client.new.send(:authenticator_for, "https://rubygems.org:8443"))
        .to have_attributes(class: Gems::APIKeyAuthenticator, key: "OTHER_KEY")
    end

    it "authenticates a host that differs only in scheme with the key stored for it" do
      stub_rubygems_configuration(api_keys: {"http://rubygems.org:443" => "OTHER_KEY", TEST_HOST => "HOST_KEY"})

      expect(Gems::Client.new.send(:authenticator_for, "http://rubygems.org:443"))
        .to have_attributes(class: Gems::APIKeyAuthenticator, key: "OTHER_KEY")
    end

    it "keeps a configured key for another host" do
      stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"})

      expect(Gems::Client.new(key: TEST_KEY).send(:authenticator_for, "https://gems.example.com"))
        .to have_attributes(class: Gems::APIKeyAuthenticator, key: TEST_KEY)
    end
  end

  describe "#credentials_configured?" do
    it "is false when the client falls back to the key stored for its host" do
      stub_rubygems_configuration

      expect(Gems::Client.new.send(:credentials_configured?)).to be(false)
    end

    it "is true with a key given to the client" do
      expect(Gems::Client.new(key: TEST_KEY).send(:credentials_configured?)).to be(true)
    end

    it "is true with a key of nil given to the client" do
      expect(Gems::Client.new(key: nil).send(:credentials_configured?)).to be(true)
    end

    it "is true with a configured key" do
      Gems.key = TEST_KEY

      expect(Gems::Client.new.send(:credentials_configured?)).to be(true)
    end

    it "is true with a configured key of nil" do
      Gems.key = nil

      expect(Gems::Client.new.send(:credentials_configured?)).to be(true)
    end

    it "is true with a username and a password" do
      stub_rubygems_configuration
      client = Gems::Client.new(username: TEST_USERNAME, password: TEST_PASSWORD)

      expect(client.send(:credentials_configured?)).to be(true)
    end

    it "is false with a username alone, which authenticates nothing" do
      stub_rubygems_configuration

      expect(Gems::Client.new(username: TEST_USERNAME).send(:credentials_configured?)).to be(false)
    end

    it "is false with a password alone, which authenticates nothing" do
      stub_rubygems_configuration

      expect(Gems::Client.new(password: TEST_PASSWORD).send(:credentials_configured?)).to be(false)
    end

    it "is false with an ID token, which is exchanged for a key the host it was exchanged with issued" do
      stub_rubygems_configuration

      expect(Gems::Client.new(id_token: "ID_TOKEN").send(:credentials_configured?)).to be(false)
    end

    it "is false with only a one-time passcode" do
      stub_rubygems_configuration

      expect(Gems::Client.new(otp: "123456").send(:credentials_configured?)).to be(false)
    end
  end

  describe "#initialize_authenticator" do
    it "uses no authentication without credentials" do
      expect(client.authenticator).to be_an_instance_of(Gems::Authenticator)
    end

    it "uses API key authentication with a key" do
      client = Gems::Client.new(key: TEST_KEY, username: nil, password: nil)

      expect(client.authenticator).to be_an_instance_of(Gems::APIKeyAuthenticator)
    end

    it "uses basic authentication with a username and password" do
      client = Gems::Client.new(key: nil, username: TEST_USERNAME, password: TEST_PASSWORD)

      expect(client.authenticator).to be_an_instance_of(Gems::BasicAuthenticator)
    end

    it "prefers basic authentication over API key authentication" do
      client = Gems::Client.new(key: TEST_KEY, username: TEST_USERNAME, password: TEST_PASSWORD)

      expect(client.authenticator).to be_an_instance_of(Gems::BasicAuthenticator)
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

      expect(client.authenticator).to be_an_instance_of(Gems::OTPAuthenticator)
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

  describe "#otp_authenticator" do
    it "returns the authenticator unchanged without a one-time passcode" do
      client = Gems::Client.new(key: TEST_KEY, username: nil, password: nil, otp: nil)

      expect(client.authenticator).to be_an_instance_of(Gems::APIKeyAuthenticator)
    end

    it "wraps the authenticator with the one-time passcode" do
      client = Gems::Client.new(key: TEST_KEY, username: nil, password: nil, otp: "123456")

      expect([client.authenticator.otp, client.authenticator.authenticator]).to eq(["123456", client.authenticator.authenticator])
    end

    it "wraps the credential authenticator" do
      client = Gems::Client.new(key: TEST_KEY, username: nil, password: nil, otp: "123456")

      expect(client.authenticator.authenticator).to be_an_instance_of(Gems::APIKeyAuthenticator)
    end

    it "sends the one-time passcode with requests" do
      client = Gems::Client.new(key: TEST_KEY, username: nil, password: nil, otp: "123456")
      stub_get("/path")
      client.get("/path")

      expect(a_get("/path").with(headers: {"Authorization" => TEST_KEY, "OTP" => "123456"})).to have_been_made
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
      expect(client.authenticator.connection).to equal(client.send(:connection))
    end

    it "builds an authenticator with the client's request builder" do
      expect(client.authenticator.request_builder).to equal(client.send(:request_builder))
    end

    it "builds an authenticator with the client's redirect handler, so the exchange follows what the client does" do
      expect(client.authenticator.redirect_handler).to equal(client.send(:redirect_handler))
    end

    it "builds an authenticator with the client's retry handler, so the exchange retries what the client does" do
      expect(client.authenticator.retry_handler).to equal(client.send(:retry_handler))
    end

    it "sends the exchange again as many times as the client's max_retries, which can be changed afterwards" do
      client.max_retries = 5

      expect(client.authenticator.retry_handler.max_retries).to eq(5)
    end

    it "keeps the authenticator when another credential changes, so the exchanged key is not thrown away" do
      authenticator = client.authenticator
      client.otp = "123456"

      expect(client.authenticator.authenticator).to equal(authenticator)
    end

    it "builds another authenticator for another ID token" do
      authenticator = client.authenticator
      client.id_token = "OTHER_ID_TOKEN"

      expect(client.authenticator).not_to equal(authenticator)
    end

    it "builds another authenticator for another host, which the token is exchanged with" do
      authenticator = client.authenticator
      client.host = "http://gems.example.com"

      expect(client.authenticator).not_to equal(authenticator)
    end

    context "when a request has exchanged the ID token" do
      let(:exchange_url) { "http://example.com/api/v1/oidc/trusted_publisher/exchange_token" }

      before do
        stub_request(:post, exchange_url)
          .to_return(body: fixture("exchange_token.json"), headers: {"Content-Type" => "application/json"})
        stub_request(:get, "http://example.com/api/v1/gems/rails.json")
          .to_return(body: fixture("rails.json"), headers: {"Content-Type" => "application/json"})
      end

      it "exchanges the token once across a credential change, since it is exchanged once per token" do
        client.rubygem("rails")
        client.otp = "123456"
        client.rubygem("rails")

        expect(a_request(:post, exchange_url)).to have_been_made.once
      end
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

    it "resolves the key of an API key object" do
      client.key = Gems::APIKey.new("rubygems_api_key" => TEST_KEY)

      expect(client.key).to eq(TEST_KEY)
    end

    it "reinitializes the authenticator" do
      client.key = TEST_KEY

      expect(client.authenticator).to be_an_instance_of(Gems::APIKeyAuthenticator)
    end

    it "removes authentication when cleared" do
      client = Gems::Client.new(key: TEST_KEY, username: nil, password: nil)
      client.key = nil

      expect(client.authenticator).to be_an_instance_of(Gems::Authenticator)
    end

    it "records the key as configured, so that it is sent to every host" do
      stub_rubygems_configuration
      client = Gems::Client.new
      client.key = TEST_KEY

      expect(client.send(:credentials_configured?)).to be(true)
    end
  end

  describe "#otp=" do
    it "sets the one-time passcode" do
      client.otp = "123456"

      expect(client.otp).to eq("123456")
    end

    it "reinitializes the authenticator" do
      client.otp = "123456"

      expect(client.authenticator).to be_an_instance_of(Gems::OTPAuthenticator)
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

  describe "#resolve_key_for_host" do
    before { stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"}) }

    it "resolves the key stored for the new host" do
      client = Gems::Client.new
      client.host = "https://gems.example.com"

      expect(client.key).to eq("HOST_KEY")
    end

    it "resolves it again for each host" do
      client = Gems::Client.new(host: "https://gems.example.com")
      client.host = TEST_HOST

      expect(client.key).to eq("FILE_KEY")
    end

    it "authenticates a request to the new host with the key stored for it" do
      client = Gems::Client.new
      client.host = "https://gems.example.com"

      expect(client.authenticator.key).to eq("HOST_KEY")
    end

    it "keeps a key configured for the client" do
      client = Gems::Client.new(key: TEST_KEY)
      client.host = "https://gems.example.com"

      expect(client.key).to eq(TEST_KEY)
    end

    it "keeps a key configured globally" do
      Gems.key = TEST_KEY
      client = Gems::Client.new
      client.host = "https://gems.example.com"

      expect(client.key).to eq(TEST_KEY)
    end

    it "keeps a key of nil given to the client" do
      client.host = "https://gems.example.com"

      expect(client.key).to be_nil
    end
  end
end
