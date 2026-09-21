# frozen_string_literal: true

RSpec.describe Gems::Client do
  subject(:client) { described_class.new(key: nil, username: nil, password: nil) }

  describe ".new" do
    # Builds a client with a block that stubs its close, so that an example can ask whether it was closed, and runs
    # the action the example gives it, such as raising.
    def client_given_to_block(&action)
      client = nil
      described_class.new(key: nil) do |built|
        client = built
        allow(built).to receive(:close)
        action&.call
      end
      client
    rescue RuntimeError
      client
    end

    it "returns the client without a block" do
      expect(described_class.new(key: nil)).to be_a(described_class)
    end

    it "gives the client to a block" do
      expect { |block| described_class.new(key: nil, &block) }.to yield_with_args(described_class)
    end

    it "builds the client from the options it is given" do
      expect(described_class.new(key: nil, host: "https://gems.example.com", &:host)).to eq("https://gems.example.com")
    end

    it "returns what the block returns" do
      expect(described_class.new(key: nil) { "returned" }).to eq("returned")
    end

    it "closes the connections of the client once the block is done with it" do
      expect(client_given_to_block).to have_received(:close)
    end

    it "closes the connections of the client when the block raises" do
      expect(client_given_to_block { raise "boom" }).to have_received(:close)
    end

    it "raises what the block raised" do
      expect { described_class.new(key: nil) { raise "boom" } }.to raise_error("boom")
    end
  end

  describe "#initialize" do
    it "defaults the host to the global configuration" do
      Gems.host = "http://example.com"

      expect(described_class.new.host).to eq("http://example.com")
    end

    it "raises an ArgumentError for a host without a scheme" do
      expect { described_class.new(host: "rubygems.org") }.to raise_error(ArgumentError, "Invalid host: rubygems.org")
    end

    it "raises an ArgumentError for a host that is not an HTTP or HTTPS URL" do
      expect { described_class.new(host: "ftp://rubygems.org") }
        .to raise_error(ArgumentError, "Invalid host: ftp://rubygems.org")
    end

    it "raises an ArgumentError for a host that cannot be parsed" do
      expect { described_class.new(host: "not a url") }.to raise_error(ArgumentError, "Invalid host: not a url")
    end

    it "raises an ArgumentError for a URL with an empty host" do
      expect { described_class.new(host: "https://") }.to raise_error(ArgumentError, "Invalid host: https://")
    end

    it "raises an ArgumentError for a URL without a host" do
      expect { described_class.new(host: "https:") }.to raise_error(ArgumentError, "Invalid host: https:")
    end

    it "raises an ArgumentError for a host that is not a URL at all" do
      expect { described_class.new(host: nil) }.to raise_error(ArgumentError, "Invalid host: ")
    end

    it "reads the API key stored for its host when no key is configured" do
      stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"})

      expect(described_class.new(host: "https://gems.example.com").key).to eq("HOST_KEY")
    end

    it "prefers a configured key to the key stored for its host" do
      stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"})
      Gems.key = TEST_KEY

      expect(described_class.new(host: "https://gems.example.com").key).to eq(TEST_KEY)
    end

    it "defaults the key to the global configuration" do
      Gems.key = TEST_KEY

      expect(described_class.new.key).to eq(TEST_KEY)
    end

    it "defaults the username to the global configuration" do
      Gems.username = TEST_USERNAME

      expect(described_class.new.username).to eq(TEST_USERNAME)
    end

    it "defaults the password to the global configuration" do
      Gems.password = TEST_PASSWORD

      expect(described_class.new.password).to eq(TEST_PASSWORD)
    end

    it "defaults the one-time passcode to the global configuration" do
      Gems.otp = "123456"

      expect(described_class.new.otp).to eq("123456")
    end

    it "defaults the ID token to the global configuration" do
      Gems.id_token = "ID_TOKEN"

      expect(described_class.new.id_token).to eq("ID_TOKEN")
    end

    it "defaults the user agent to the global configuration" do
      Gems.user_agent = "Custom User Agent"

      expect(described_class.new.user_agent).to eq("Custom User Agent")
    end

    {open_timeout: 10, read_timeout: 20, write_timeout: 30, keep_alive_timeout: 40, debug_output: $stderr,
     proxy_url: "http://proxy.example.com:8080", max_redirects: 3, max_retries: 3,
     max_retry_delay: 30}.each do |option, value|
      it "defaults the #{option} to the global configuration" do
        Gems.public_send(:"#{option}=", value)

        expect(described_class.new.public_send(option)).to eq(value)
      end
    end

    it "defaults the open timeout" do
      expect(client.open_timeout).to eq(Gems::Connection::DEFAULT_OPEN_TIMEOUT)
    end

    it "defaults the read timeout" do
      expect(client.read_timeout).to eq(Gems::Connection::DEFAULT_READ_TIMEOUT)
    end

    it "defaults the write timeout" do
      expect(client.write_timeout).to eq(Gems::Connection::DEFAULT_WRITE_TIMEOUT)
    end

    it "defaults the keep-alive timeout" do
      expect(client.keep_alive_timeout).to eq(Gems::Connection::DEFAULT_KEEP_ALIVE_TIMEOUT)
    end

    it "defaults the debug output to nil" do
      expect(client.debug_output).to be_nil
    end

    it "defaults the proxy URL to nil" do
      expect(client.proxy_url).to be_nil
    end

    it "defaults the maximum redirects" do
      expect(client.max_redirects).to eq(Gems::RedirectHandler::DEFAULT_MAX_REDIRECTS)
    end

    it "defaults the maximum retries" do
      expect(client.max_retries).to eq(Gems::RetryHandler::DEFAULT_MAX_RETRIES)
    end

    it "defaults the maximum retry delay" do
      expect(client.max_retry_delay).to eq(Gems::RetryHandler::DEFAULT_MAX_RETRY_DELAY)
    end

    it "initializes the authenticator from the credentials" do
      client = described_class.new(key: TEST_KEY)

      expect(client.authenticator).to be_an_instance_of(Gems::APIKeyAuthenticator)
    end

    context "with custom options" do
      subject(:client) do
        described_class.new(host: "http://example.com", key: TEST_KEY, username: TEST_USERNAME, password: TEST_PASSWORD,
          otp: "123456", id_token: "ID_TOKEN", user_agent: "Custom User Agent", open_timeout: 10, read_timeout: 20,
          write_timeout: 30, keep_alive_timeout: 40, debug_output: $stderr,
          proxy_url: "http://proxy.example.com:8080", max_redirects: 3, max_retries: 3, max_retry_delay: 30)
      end

      it "sets the host" do
        expect(client.host).to eq("http://example.com")
      end

      it "sets the credentials" do
        expect([client.key, client.username, client.password, client.otp, client.id_token])
          .to eq([TEST_KEY, TEST_USERNAME, TEST_PASSWORD, "123456", "ID_TOKEN"])
      end

      it "sets the user agent" do
        expect(client.user_agent).to eq("Custom User Agent")
      end

      it "sets the open timeout" do
        expect(client.open_timeout).to eq(10)
      end

      it "sets the read timeout" do
        expect(client.read_timeout).to eq(20)
      end

      it "sets the write timeout" do
        expect(client.write_timeout).to eq(30)
      end

      it "sets the keep-alive timeout" do
        expect(client.keep_alive_timeout).to eq(40)
      end

      it "sets the debug output" do
        expect(client.debug_output).to equal($stderr)
      end

      it "sets the proxy URL" do
        expect(client.proxy_url).to eq("http://proxy.example.com:8080")
      end

      it "sets the maximum redirects" do
        expect(client.max_redirects).to eq(3)
      end

      it "sets the maximum retries" do
        expect(client.max_retries).to eq(3)
      end

      it "sets the maximum retry delay" do
        expect(client.max_retry_delay).to eq(30)
      end
    end

    it "builds a client that parses responses" do
      stub_get("/path").to_return(body: "body")

      expect(client.get("/path")).to eq("body")
    end

    it "keeps the connection private" do
      expect(client).not_to respond_to(:connection)
    end

    it "keeps the request builder private" do
      expect(client).not_to respond_to(:request_builder)
    end

    it "keeps execute_request private" do
      expect(client).not_to respond_to(:execute_request)
    end

    it "shares the connection with the redirect handler" do
      redirect_handler = client.instance_variable_get(:@redirect_handler)

      expect(redirect_handler.connection).to equal(client.instance_variable_get(:@connection))
    end

    it "shares the request builder with the redirect handler" do
      redirect_handler = client.instance_variable_get(:@redirect_handler)

      expect(redirect_handler.request_builder).to equal(client.instance_variable_get(:@request_builder))
    end
  end

  describe "#inspect" do
    it "shows the host and authenticator without credentials" do
      client = described_class.new(host: "http://example.com", key: TEST_KEY, username: nil, password: nil)

      expect(client.inspect).to eq('#<Gems::Client host="http://example.com" authenticator=#<Gems::APIKeyAuthenticator>>')
    end
  end

  describe "#close" do
    it "returns the client" do
      expect(client.close).to equal(client)
    end

    it "closes the connections the client keeps open" do
      connection = client.instance_variable_get(:@connection)
      allow(connection).to receive(:close)
      client.close

      expect(connection).to have_received(:close)
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

    it "raises an ArgumentError for an invalid host" do
      expect { client.host = "rubygems.org" }.to raise_error(ArgumentError, "Invalid host: rubygems.org")
    end

    it "leaves the host as it was after an invalid host" do
      client.host = "rubygems.org"
    rescue ArgumentError
      expect(client.host).to eq(TEST_HOST)
    end

    context "when a key is stored for the new host" do
      let(:client) { described_class.new }

      before do
        stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"})
        stub_request(:post, "https://gems.example.com/path")
      end

      it "resolves the key stored for the new host" do
        client.host = "https://gems.example.com"

        expect(client.key).to eq("HOST_KEY")
      end

      it "sends the key stored for the new host" do
        client.host = "https://gems.example.com"
        client.post("/path")

        expect(a_request(:post, "https://gems.example.com/path")
          .with(headers: {"Authorization" => "HOST_KEY"})).to have_been_made
      end

      it "keeps a key configured for the client" do
        client = described_class.new(key: TEST_KEY)
        client.host = "https://gems.example.com"

        expect(client.key).to eq(TEST_KEY)
      end

      it "keeps a key configured globally" do
        Gems.key = TEST_KEY
        client = described_class.new
        client.host = "https://gems.example.com"

        expect(client.key).to eq(TEST_KEY)
      end
    end

    context "when no key is stored for the new host" do
      let(:client) { described_class.new }

      before do
        stub_rubygems_configuration(rubygems_api_key: nil)
        stub_request(:post, "https://gems.example.com/path")
      end

      it "sends no key to the new host" do
        client.host = "https://gems.example.com"
        client.post("/path")

        expect(a_request(:post, "https://gems.example.com/path")
          .with { |request| !request.headers.key?("Authorization") }).to have_been_made
      end
    end
  end

  %i[open_timeout read_timeout write_timeout max_redirects max_retries max_retry_delay].each do |option|
    describe "##{option}=" do
      it "sets the #{option}" do
        client.public_send(:"#{option}=", 42)

        expect(client.public_send(option)).to eq(42)
      end
    end
  end

  describe "#debug_output=" do
    it "sets the debug output" do
      client.debug_output = $stderr

      expect(client.debug_output).to equal($stderr)
    end
  end

  describe "#proxy_url=" do
    it "sets the proxy URL" do
      client.proxy_url = "http://proxy.example.com:8080"

      expect(client.proxy_url).to eq("http://proxy.example.com:8080")
    end

    it "clears the proxy URL" do
      client.proxy_url = "http://proxy.example.com:8080"
      client.proxy_url = nil

      expect(client.proxy_url).to be_nil
    end
  end

  describe "#user_agent=" do
    it "sets the user agent" do
      client.user_agent = "Custom User Agent"

      expect(client.user_agent).to eq("Custom User Agent")
    end

    it "sends the user agent with requests" do
      client.user_agent = "Custom User Agent"
      stub_get("/path")
      client.get("/path")

      expect(a_get("/path").with(headers: {"User-Agent" => "Custom User Agent"})).to have_been_made
    end
  end

  describe "#get" do
    it "performs a GET request" do
      stub_get("/path").to_return(body: "body")

      expect(client.get("/path")).to eq("body")
    end

    it "sends query parameters" do
      stub_get("/path?query=cucumber&page=2")
      client.get("/path", {query: "cucumber", page: 2})

      expect(a_get("/path?query=cucumber&page=2")).to have_been_made
    end

    it "uses a custom host" do
      stub_request(:get, "http://example.com/path")
      client.get("/path", host: "http://example.com")

      expect(a_request(:get, "http://example.com/path")).to have_been_made
    end

    it "raises an ArgumentError for an invalid per-request host" do
      expect { client.get("/path", host: "example.com") }.to raise_error(ArgumentError, "Invalid host: example.com")
    end

    it "sends headers of its own" do
      stub_get("/path")
      client.get("/path", headers: {"Accept" => "application/json"})

      expect(a_get("/path").with(headers: {"Accept" => "application/json"})).to have_been_made
    end

    it "authenticates a request to another host with the key stored for it" do
      stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"})
      stub_request(:post, "https://gems.example.com/path")
      described_class.new.post("/path", host: "https://gems.example.com")

      expect(a_request(:post, "https://gems.example.com/path")
        .with(headers: {"Authorization" => "HOST_KEY"})).to have_been_made
    end

    it "sends the one-time passcode with the key stored for another host" do
      stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"})
      stub_request(:post, "https://gems.example.com/path")
      described_class.new(otp: "123456").post("/path", host: "https://gems.example.com")

      expect(a_request(:post, "https://gems.example.com/path")
        .with(headers: {"Authorization" => "HOST_KEY", "OTP" => "123456"})).to have_been_made
    end

    it "sends no credentials to another host without a stored key" do
      stub_rubygems_configuration(rubygems_api_key: nil)
      stub_request(:post, "https://gems.example.com/path")
      described_class.new.post("/path", host: "https://gems.example.com")

      expect(a_request(:post, "https://gems.example.com/path")
        .with { |request| !request.headers.key?("Authorization") }).to have_been_made
    end

    it "sends a configured key to another host" do
      stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"})
      stub_request(:post, "https://gems.example.com/path")
      described_class.new(key: TEST_KEY).post("/path", host: "https://gems.example.com")

      expect(a_request(:post, "https://gems.example.com/path")
        .with(headers: {"Authorization" => TEST_KEY})).to have_been_made
    end

    it "sends configured basic authentication to another host" do
      stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"})
      stub_request(:post, "https://gems.example.com/path")
      described_class.new(username: TEST_USERNAME, password: TEST_PASSWORD).post("/path", host: "https://gems.example.com")

      expect(a_request(:post, "https://gems.example.com/path")
        .with(basic_auth: [TEST_USERNAME, TEST_PASSWORD])).to have_been_made
    end

    it "keeps the key of the client for its own host written another way" do
      stub_rubygems_configuration(api_keys: {TEST_HOST => "HOST_KEY"})
      stub_post("/path")
      described_class.new.post("/path", host: "https://RubyGems.org:443")

      expect(a_post("/path").with(headers: {"Authorization" => "HOST_KEY"})).to have_been_made
    end
  end

  describe "#delete" do
    it "performs a DELETE request" do
      stub_delete("/path").to_return(body: "body")

      expect(client.delete("/path")).to eq("body")
    end

    it "sends query parameters" do
      stub_delete("/path?gem_name=gems&version=0.0.8")
      client.delete("/path", {gem_name: "gems", version: "0.0.8"})

      expect(a_delete("/path?gem_name=gems&version=0.0.8")).to have_been_made
    end

    it "uses a custom host" do
      stub_request(:delete, "http://example.com/path")
      client.delete("/path", host: "http://example.com")

      expect(a_request(:delete, "http://example.com/path")).to have_been_made
    end

    it "sends headers of its own" do
      stub_delete("/path")
      client.delete("/path", headers: {"Accept" => "application/json"})

      expect(a_delete("/path").with(headers: {"Accept" => "application/json"})).to have_been_made
    end
  end

  %i[post put patch].each do |http_method|
    describe "##{http_method}" do
      it "performs a #{http_method.upcase} request" do
        stub_request(http_method, rubygems_url("/path")).to_return(body: "body")

        expect(client.public_send(http_method, "/path")).to eq("body")
      end

      it "sends an empty form body by default" do
        stub_request(http_method, rubygems_url("/path"))
        client.public_send(http_method, "/path")

        expect(a_request(http_method, rubygems_url("/path"))
          .with(body: "", headers: {"Content-Type" => "application/x-www-form-urlencoded"})).to have_been_made
      end

      it "sends a form-encoded body" do
        stub_request(http_method, rubygems_url("/path"))
        client.public_send(http_method, "/path", {gem_name: "gems", version: "0.0.8"})

        expect(a_request(http_method, rubygems_url("/path")).with(body: "gem_name=gems&version=0.0.8")).to have_been_made
      end

      it "sends a binary body" do
        stub_request(http_method, rubygems_url("/path"))
        client.public_send(http_method, "/path", "data")

        expect(a_request(http_method, rubygems_url("/path"))
          .with(body: "data", headers: {"Content-Type" => "application/octet-stream"})).to have_been_made
      end

      it "sends a body with a custom content type" do
        stub_request(http_method, rubygems_url("/path"))
        client.public_send(http_method, "/path", "{}", content_type: "application/json")

        expect(a_request(http_method, rubygems_url("/path"))
          .with(body: "{}", headers: {"Content-Type" => "application/json"})).to have_been_made
      end

      it "uses a custom host" do
        stub_request(http_method, "http://example.com/path")
        client.public_send(http_method, "/path", host: "http://example.com")

        expect(a_request(http_method, "http://example.com/path")).to have_been_made
      end

      it "sends headers of its own" do
        stub_request(http_method, rubygems_url("/path"))
        client.public_send(http_method, "/path", headers: {"Accept" => "application/json"})

        expect(a_request(http_method, rubygems_url("/path"))
          .with(headers: {"Accept" => "application/json"})).to have_been_made
      end
    end
  end

  def multipart_body
    @multipart_body ||= [["gem", "GEM DATA", {filename: "gems-0.0.8.gem", content_type: "application/octet-stream"}]]
  end

  # The requests the connection performs, which show the multipart fields that WebMock cannot read from a request
  def performed_requests
    connection = client.instance_variable_get(:@connection)
    requests = []
    allow(connection).to receive(:perform).and_wrap_original do |perform, request:|
      requests << request
      perform.call(request:)
    end
    requests
  end

  describe "#execute_request" do
    # Answers the first request sent on the client's connection with 429 and the rest with 200, collecting the body
    # each one carried, so that an example can ask what every attempt sent.
    def bodies_of_requests_sent
      allow(client.instance_variable_get(:@retry_handler)).to receive(:sleep)
      sent = []
      allow(client.instance_variable_get(:@connection)).to receive(:perform) do |request:|
        sent << request.body_stream.read
        sent.one? ? build_response(Net::HTTPTooManyRequests, "429", "Too Many Requests", "throttled") : build_response(Net::HTTPOK, "200", "OK", "body")
      end
      sent
    end

    it "joins the path with the host" do
      client.host = "http://example.com/"
      stub_request(:get, "http://example.com/path")
      client.get("/path")

      expect(a_request(:get, "http://example.com/path")).to have_been_made
    end

    it "keeps a path prefix on the host" do
      client.host = "http://example.com/gems"
      stub_request(:get, "http://example.com/gems/path")
      client.get("/path")

      expect(a_request(:get, "http://example.com/gems/path")).to have_been_made
    end

    it "keeps a path prefix on a per-request host" do
      stub_request(:get, "http://example.com/gems/path")
      client.get("/path", host: "http://example.com/gems/")

      expect(a_request(:get, "http://example.com/gems/path")).to have_been_made
    end

    it "refuses a path that is a URL of another host" do
      expect { client.get("https://gems.example.com/path") }
        .to raise_error(ArgumentError, "Path is not on https://rubygems.org: https://gems.example.com/path")
    end

    it "refuses a path that is a URL of another host than the one the request is for" do
      expect { client.get("https://gems.example.com/other", host: "http://example.com") }
        .to raise_error(ArgumentError, "Path is not on http://example.com: https://gems.example.com/other")
    end

    it "refuses a path that is a URL of another port on the host" do
      expect { client.get("https://rubygems.org:8080/path") }
        .to raise_error(ArgumentError, "Path is not on https://rubygems.org: https://rubygems.org:8080/path")
    end

    it "sends a path that is a URL of the host itself" do
      stub_get("/path")
      client.get("https://rubygems.org/path")

      expect(a_get("/path")).to have_been_made
    end

    it "keeps a path that begins with two slashes on the host" do
      stub_get("/gems.example.com/path")
      client.get("//gems.example.com/path")

      expect(a_get("/gems.example.com/path")).to have_been_made
    end

    it "sends request bodies" do
      stub_post("/path")
      client.post("/path", {gem_name: "gems"})

      expect(a_post("/path").with(body: "gem_name=gems")).to have_been_made
    end

    it "sends query parameters" do
      stub_get("/path?page=2")
      client.get("/path", {page: 2})

      expect(a_get("/path?page=2")).to have_been_made
    end

    it "sends a custom content type" do
      stub_post("/path")
      client.post("/path", "{}", content_type: "application/json")

      expect(a_post("/path").with(headers: {"Content-Type" => "application/json"})).to have_been_made
    end

    it "uses a custom host" do
      stub_request(:get, "http://example.com/path")
      client.get("/path", host: "http://example.com")

      expect(a_request(:get, "http://example.com/path")).to have_been_made
    end

    it "raises an ArgumentError for an invalid per-request host" do
      expect { client.get("/path", host: "example.com") }.to raise_error(ArgumentError, "Invalid host: example.com")
    end

    it "sends headers of its own" do
      stub_get("/path")
      client.get("/path", headers: {"Accept" => "application/json"})

      expect(a_get("/path").with(headers: {"Accept" => "application/json"})).to have_been_made
    end

    it "authenticates a request to another host with the key stored for it" do
      stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"})
      stub_request(:post, "https://gems.example.com/path")
      described_class.new.post("/path", host: "https://gems.example.com")

      expect(a_request(:post, "https://gems.example.com/path")
        .with(headers: {"Authorization" => "HOST_KEY"})).to have_been_made
    end

    it "sends the one-time passcode with the key stored for another host" do
      stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"})
      stub_request(:post, "https://gems.example.com/path")
      described_class.new(otp: "123456").post("/path", host: "https://gems.example.com")

      expect(a_request(:post, "https://gems.example.com/path")
        .with(headers: {"Authorization" => "HOST_KEY", "OTP" => "123456"})).to have_been_made
    end

    it "sends no credentials to another host without a stored key" do
      stub_rubygems_configuration(rubygems_api_key: nil)
      stub_request(:post, "https://gems.example.com/path")
      described_class.new.post("/path", host: "https://gems.example.com")

      expect(a_request(:post, "https://gems.example.com/path")
        .with { |request| !request.headers.key?("Authorization") }).to have_been_made
    end

    it "sends a configured key to another host" do
      stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"})
      stub_request(:post, "https://gems.example.com/path")
      described_class.new(key: TEST_KEY).post("/path", host: "https://gems.example.com")

      expect(a_request(:post, "https://gems.example.com/path")
        .with(headers: {"Authorization" => TEST_KEY})).to have_been_made
    end

    it "sends configured basic authentication to another host" do
      stub_rubygems_configuration(api_keys: {"https://gems.example.com" => "HOST_KEY"})
      stub_request(:post, "https://gems.example.com/path")
      described_class.new(username: TEST_USERNAME, password: TEST_PASSWORD).post("/path", host: "https://gems.example.com")

      expect(a_request(:post, "https://gems.example.com/path")
        .with(basic_auth: [TEST_USERNAME, TEST_PASSWORD])).to have_been_made
    end

    it "keeps the key of the client for its own host written another way" do
      stub_rubygems_configuration(api_keys: {TEST_HOST => "HOST_KEY"})
      stub_post("/path")
      described_class.new.post("/path", host: "https://RubyGems.org:443")

      expect(a_post("/path").with(headers: {"Authorization" => "HOST_KEY"})).to have_been_made
    end

    it "authenticates requests" do
      client.key = TEST_KEY
      stub_get("/path")
      client.get("/path")

      expect(a_get("/path").with(headers: {"Authorization" => TEST_KEY})).to have_been_made
    end

    it "does not authenticate requests without credentials" do
      stub_get("/path")
      client.get("/path")

      expect(a_get("/path").with { |request| !request.headers.key?("Authorization") }).to have_been_made
    end

    it "follows redirects" do
      stub_get("/old").to_return(status: 302, headers: {"Location" => "https://bundler.rubygems.org/new"})
      stub_request(:get, "https://bundler.rubygems.org/new").to_return(body: "redirected")

      expect(client.get("/old")).to eq("redirected")
    end

    it "preserves authentication across redirects" do
      client.key = TEST_KEY
      stub_get("/old").to_return(status: 302, headers: {"Location" => "/new"})
      stub_get("/new")
      client.get("/old")

      expect(a_get("/new").with(headers: {"Authorization" => TEST_KEY})).to have_been_made
    end

    it "preserves the headers of the caller across redirects" do
      stub_get("/old").to_return(status: 302, headers: {"Location" => "/new"})
      stub_get("/new")
      client.get("/old", headers: {"X-Trace-Id" => "abc123"})

      expect(a_get("/new").with(headers: {"X-Trace-Id" => "abc123"})).to have_been_made
    end

    it "raises TooManyRedirects for redirect loops" do
      stub_get("/loop").to_return(status: 302, headers: {"Location" => "/loop"})

      expect { client.get("/loop") }.to raise_error(Gems::TooManyRedirects)
    end

    it "preserves a multipart body across a 307 redirect" do
      stub_post("/old").to_return(status: 307, headers: {"Location" => "/new"})
      stub_post("/new")
      requests = performed_requests
      client.post("/old", multipart_body)

      expect(requests.last.instance_variable_get(:@body_data)).to equal(multipart_body)
    end

    it "preserves a raw body and its content type across a 307 redirect" do
      stub_put("/old").to_return(status: 307, headers: {"Location" => "/new"})
      stub_put("/new")
      client.put("/old", "raw", content_type: "text/plain")

      expect(a_put("/new").with(body: "raw", headers: {"Content-Type" => "text/plain"})).to have_been_made
    end

    it "raises TooManyRequests rather than retrying by default" do
      stub_get("/path").to_return(status: 429, body: "throttled")

      expect { client.get("/path") }.to raise_error(Gems::TooManyRequests)
    end

    it "does not send a request that is not idempotent again" do
      client.max_retries = 1
      stub_post("/path").to_return({status: 429, body: "throttled"}, {body: "body"})

      expect { client.post("/path") }.to raise_error(Gems::TooManyRequests)
    end

    it "sends a rate-limited request again once retries are allowed" do
      client.max_retries = 1
      allow(client.instance_variable_get(:@retry_handler)).to receive(:sleep)
      stub_get("/path").to_return({status: 429, headers: {"Retry-After" => "1"}}, {body: "body"})

      expect(client.get("/path")).to eq("body")
    end

    it "sends an idempotent request lost to the network again" do
      client.max_retries = 1
      allow(client.instance_variable_get(:@retry_handler)).to receive(:sleep)
      stub_get("/path").to_raise(Errno::ECONNREFUSED).then.to_return(body: "body")

      expect(client.get("/path")).to eq("body")
    end

    it "follows the redirects of a request it sends again" do
      client.max_retries = 1
      allow(client.instance_variable_get(:@retry_handler)).to receive(:sleep)
      stub_get("/old").to_return({status: 429}, {status: 302, headers: {"Location" => "/new"}})
      stub_get("/new").to_return(body: "redirected")

      expect(client.get("/old")).to eq("redirected")
    end

    it "sends the whole of a body read as a stream again, rather than the bytes the attempt before it left" do
      client.max_retries = 1
      gem_bytes = File.binread(File.join(fixture_path, "gems-0.0.8.gem"))
      sent = bodies_of_requests_sent

      client.put("/path", fixture("gems-0.0.8.gem"))

      expect(sent).to eq([gem_bytes, gem_bytes])
    end

    it "raises NotFound for 404 responses" do
      stub_get("/path").to_return(status: 404, body: "This rubygem could not be found.")

      expect { client.get("/path") }.to raise_error(Gems::NotFound, "This rubygem could not be found.")
    end

    it "raises Error for other error responses" do
      stub_get("/path").to_return(status: 500, body: "Internal Server Error")

      expect { client.get("/path") }.to raise_error(Gems::Error, "Internal Server Error")
    end

    it "raises NetworkError for network errors" do
      stub_get("/path").to_raise(Errno::ECONNREFUSED)

      expect { client.get("/path") }.to raise_error(Gems::NetworkError)
    end
  end
end
