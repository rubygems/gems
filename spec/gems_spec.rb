# frozen_string_literal: true

RSpec.describe Gems do
  it "extends Gems::Configuration" do
    expect(described_class).to be_a(Gems::Configuration)
  end

  describe "::VERSION" do
    it "is a String" do
      expect(Gems::VERSION).to be_a(String)
    end

    it "is a valid gem version" do
      expect(Gem::Version.correct?(Gems::VERSION)).to be(true)
    end
  end

  describe ".new" do
    it "returns a Gems::Client" do
      expect(described_class.new).to be_an_instance_of(Gems::Client)
    end

    it "passes options to the client" do
      client = described_class.new(key: TEST_KEY, host: "http://example.com", max_redirects: 3)

      expect([client.key, client.host, client.max_redirects]).to eq([TEST_KEY, "http://example.com", 3])
    end
  end

  describe ".client" do
    it "returns a Gems::Client" do
      expect(described_class.client).to be_an_instance_of(Gems::Client)
    end

    it "builds the client from the global configuration" do
      described_class.configure { |config| config.key, config.host, config.max_redirects = TEST_KEY, "http://example.com", 3 }
      client = described_class.client

      expect([client.key, client.host, client.max_redirects]).to eq([TEST_KEY, "http://example.com", 3])
    end

    it "returns the same client while the configuration is unchanged" do
      expect(described_class.client).to equal(described_class.client)
    end

    {host: "http://example.com", id_token: "ID_TOKEN"}.each do |option, value|
      it "builds a new client when #{option} changes" do
        client = described_class.client
        described_class.public_send(:"#{option}=", value)

        expect(described_class.client).not_to equal(client)
      end
    end

    it "builds a new client when the API key it falls back to changes" do
      stub_rubygems_configuration(rubygems_api_key: "FILE_KEY")
      client = described_class.client
      stub_rubygems_configuration(rubygems_api_key: "OTHER_FILE_KEY")

      expect(described_class.client).not_to equal(client)
    end

    it "gives the new client the API key it falls back to" do
      stub_rubygems_configuration(rubygems_api_key: "FILE_KEY")
      described_class.client
      stub_rubygems_configuration(rubygems_api_key: "OTHER_FILE_KEY")

      expect(described_class.client.key).to eq("OTHER_FILE_KEY")
    end

    it "closes the connections of the client it replaces" do
      client = described_class.client
      allow(client).to receive(:close)
      described_class.host = "http://example.com"
      described_class.client

      expect(client).to have_received(:close)
    end

    {key: "OTHER_KEY", username: TEST_USERNAME, password: TEST_PASSWORD, otp: "123456"}.each do |option, value|
      it "keeps the client it has when the #{option} changes" do
        described_class.key = TEST_KEY
        client = described_class.client
        described_class.public_send(:"#{option}=", value)

        expect(described_class.client).to equal(client)
      end

      it "applies the #{option} to the client it has" do
        described_class.key = TEST_KEY
        described_class.client
        described_class.public_send(:"#{option}=", value)

        expect(described_class.client.public_send(option)).to eq(value)
      end
    end

    context "when a passcode is assigned after the client is built" do
      before do
        stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"})
        stub_request(:post, "https://gems.example.com/path")
        described_class.client
        described_class.otp = "123456"
      end

      it "keeps resolving the API key for the host of a request" do
        described_class.client.post("/path", host: "https://gems.example.com")

        expect(a_request(:post, "https://gems.example.com/path")
          .with(headers: {"Authorization" => "HOST_KEY", "OTP" => "123456"})).to have_been_made
      end
    end

    {
      user_agent: "Custom User Agent",
      open_timeout: 1,
      read_timeout: 1,
      write_timeout: 1,
      keep_alive_timeout: 1,
      debug_output: $stderr,
      proxy_url: "http://proxy.example.com:8080",
      max_redirects: 1
    }.each do |option, value|
      it "keeps the client it has when #{option} changes" do
        client = described_class.client
        described_class.public_send(:"#{option}=", value)

        expect(described_class.client).to equal(client)
      end

      it "applies #{option} to the client it has" do
        described_class.client
        described_class.public_send(:"#{option}=", value)

        expect(described_class.client.public_send(option)).to eq(value)
      end
    end

    it "keeps a setting assigned to the client it has" do
      described_class.client.user_agent = "Custom User Agent"

      expect(described_class.client.user_agent).to eq("Custom User Agent")
    end

    it "keeps a credential assigned to the client it has" do
      described_class.client.otp = "123456"

      expect(described_class.client.otp).to eq("123456")
    end

    context "when another client cannot be built from the configuration" do
      let(:client) { described_class.client }

      before do
        allow(client).to receive(:close)
        described_class.host = "http://example.com"
        allow(Gems::Client).to receive(:new).and_raise(ArgumentError)
      end

      it "keeps the connections of the client it has open" do
        described_class.client
      rescue ArgumentError
        expect(client).not_to have_received(:close)
      end
    end

    it "keeps a setting assigned to the client after the configuration is applied" do
      described_class.client
      described_class.user_agent = "Custom User Agent"
      described_class.client.user_agent = "Assigned User Agent"

      expect(described_class.client.user_agent).to eq("Assigned User Agent")
    end

    context "with a trusted publishing ID token" do
      let(:exchange) { stub_post("/api/v1/oidc/trusted_publisher/exchange_token").to_return(body: fixture("exchange_token.json")) }

      before do
        exchange
        stub_get("/api/v1/gems/rails.json").to_return(body: fixture("rails.json"))
        described_class.id_token = "ID_TOKEN"
      end

      it "exchanges the ID token once across calls" do
        2.times { described_class.rubygem("rails") }

        expect(exchange).to have_been_requested.once
      end

      it "keeps the exchanged API key when the rest of the configuration changes" do
        described_class.rubygem("rails")
        described_class.user_agent = "Custom User Agent"
        described_class.rubygem("rails")

        expect(exchange).to have_been_requested.once
      end

      it "keeps the exchanged API key when another credential changes" do
        described_class.rubygem("rails")
        described_class.otp = "123456"
        described_class.rubygem("rails")

        expect(exchange).to have_been_requested.once
      end
    end

    context "when threads call it at once" do
      let(:entered) { Queue.new }
      let(:proceed) { Queue.new }
      let(:built) { Queue.new }

      before do
        allow(Gems::Client).to receive(:new).and_wrap_original do |original, **options|
          built << true
          entered << true
          proceed.pop
          original.call(**options)
        end
      end

      # Call the client from two threads, with the first inside Gems::Client.new when the second starts
      def call_from_two_threads
        threads = [Thread.new { Gems.client }]
        entered.pop
        threads << Thread.new { Gems.client }
        2.times { proceed << true }
        threads.each { |thread| thread.join(5) }
      end

      it "builds one client" do
        call_from_two_threads

        expect(built.size).to eq(1)
      end
    end
  end

  describe ".reset" do
    it "returns the configuration" do
      expect(described_class.reset).to equal(described_class)
    end

    it "forgets the client built from the configuration" do
      client = described_class.client
      described_class.reset

      expect(described_class.client).not_to equal(client)
    end

    it "closes the connections of the client it forgets" do
      client = described_class.client
      allow(client).to receive(:close)
      described_class.reset

      expect(client).to have_received(:close)
    end

    context "when a client is being built" do
      let(:entered) { Queue.new }
      let(:proceed) { Queue.new }

      before do
        allow(Gems::Client).to receive(:new).and_wrap_original do |original, **options|
          entered << true
          proceed.pop
          original.call(**options)
        end
      end

      # Reset while another thread is inside Gems::Client.new, returning whether the reset waited for it
      def reset_during_build
        build = Thread.new { Gems.client }
        entered.pop
        reset = Thread.new { Gems.reset }
        waited = reset.join(0.1).nil?
        proceed << true
        [build, reset].each { |thread| thread.join(5) }
        waited
      end

      it "waits for the client to be built before forgetting it" do
        expect(reset_during_build).to be(true)
      end
    end

    it "closes nothing when no client has been built" do
      described_class.send(:remove_instance_variable, :@client) if described_class.instance_variable_defined?(:@client)

      expect(described_class.reset).to equal(described_class)
    end
  end

  Gems::API.public_instance_methods.each do |method|
    it "delegates .#{method} to a client" do
      expect(described_class).to respond_to(method)
    end
  end

  it "does not respond to undefined methods" do
    expect(described_class).not_to respond_to(:foo)
  end

  describe ".rubygem" do
    before { stub_get("/api/v1/gems/rails.json").to_return(body: fixture("rails.json")) }

    it "delegates to a client" do
      described_class.rubygem("rails")

      expect(a_get("/api/v1/gems/rails.json")).to have_been_made
    end

    it "returns the same result as a client" do
      expect(described_class.rubygem("rails")).to eq(Gems::Client.new.rubygem("rails"))
    end
  end

  describe ".version" do
    before { stub_get("/api/v2/rubygems/rails/versions/7.0.6.json").to_return(body: fixture("v2/rails-7.0.6.json")) }

    it "delegates to a client" do
      expect(described_class.version("rails", "7.0.6")).to eq(Gems::Client.new.version("rails", "7.0.6"))
    end
  end
end
