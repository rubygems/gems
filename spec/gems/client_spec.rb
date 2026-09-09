RSpec.describe Gems::Client do
  subject(:client) { described_class.new(key: nil, username: nil, password: nil) }

  describe "#initialize" do
    it "defaults the host to the global configuration" do
      Gems.host = "http://example.com"

      expect(described_class.new.host).to eq("http://example.com")
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

    {open_timeout: 10, read_timeout: 20, write_timeout: 30, debug_output: $stderr, proxy_url: "http://proxy.example.com:8080",
     max_redirects: 3}.each do |option, value|
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

    it "defaults the debug output to nil" do
      expect(client.debug_output).to be_nil
    end

    it "defaults the proxy URL to nil" do
      expect(client.proxy_url).to be_nil
    end

    it "defaults the maximum redirects" do
      expect(client.max_redirects).to eq(Gems::RedirectHandler::DEFAULT_MAX_REDIRECTS)
    end

    it "initializes the authenticator from the credentials" do
      client = described_class.new(key: TEST_KEY)

      expect(client.authenticator).to be_an_instance_of(Gems::ApiKeyAuthenticator)
    end

    context "with custom options" do
      subject(:client) do
        described_class.new(host: "http://example.com", key: TEST_KEY, username: TEST_USERNAME, password: TEST_PASSWORD,
          otp: "123456", id_token: "ID_TOKEN", user_agent: "Custom User Agent", open_timeout: 10, read_timeout: 20,
          write_timeout: 30, debug_output: $stderr, proxy_url: "http://proxy.example.com:8080", max_redirects: 3)
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

      it "sets the debug output" do
        expect(client.debug_output).to equal($stderr)
      end

      it "sets the proxy URL" do
        expect(client.proxy_url).to eq("http://proxy.example.com:8080")
      end

      it "sets the maximum redirects" do
        expect(client.max_redirects).to eq(3)
      end
    end

    it "builds a client that parses responses" do
      stub_get("/path").to_return(body: "body")

      expect(client.get("/path")).to eq("body")
    end

    it "exposes the connection" do
      expect(client.connection).to be_an_instance_of(Gems::Connection)
    end

    it "exposes the request builder" do
      expect(client.request_builder).to be_an_instance_of(Gems::RequestBuilder)
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

      expect(client.inspect).to eq('#<Gems::Client host="http://example.com" authenticator=#<Gems::ApiKeyAuthenticator>>')
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

  %i[open_timeout read_timeout write_timeout max_redirects].each do |option|
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
    end
  end

  describe "#execute_request" do
    it "joins the path with the host" do
      client.host = "http://example.com/"
      stub_request(:get, "http://example.com/path")
      client.get("/path")

      expect(a_request(:get, "http://example.com/path")).to have_been_made
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

    it "raises TooManyRedirects for redirect loops" do
      stub_get("/loop").to_return(status: 302, headers: {"Location" => "/loop"})

      expect { client.get("/loop") }.to raise_error(Gems::TooManyRedirects)
    end

    it "raises NotFound for 404 responses" do
      stub_get("/path").to_return(status: 404, body: "This rubygem could not be found.")

      expect { client.get("/path") }.to raise_error(Gems::NotFound, "This rubygem could not be found.")
    end

    it "raises Error for other error responses" do
      stub_get("/path").to_return(status: 500, body: "Internal Server Error")

      expect { client.get("/path") }.to raise_error(Gems::Error, "Internal Server Error")
    end
  end
end
