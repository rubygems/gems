RSpec.describe Gems::Request do
  let(:client) { Gems::Client.new(key: nil, username: nil, password: nil) }

  describe "#connection" do
    it "returns a connection" do
      expect(client.connection).to be_an_instance_of(Gems::Connection)
    end

    it "memoizes the connection" do
      expect(client.connection).to equal(client.connection)
    end
  end

  describe "#request_builder" do
    it "returns a request builder with the client's user agent" do
      client = Gems::Client.new(user_agent: "Custom User Agent")

      expect(client.request_builder.user_agent).to eq("Custom User Agent")
    end

    it "returns a request builder with the including object's user agent" do
      requester = Class.new { include Gems::Request }.new
      requester.define_singleton_method(:user_agent) { "Custom User Agent" }

      expect(requester.request_builder.user_agent).to eq("Custom User Agent")
    end

    it "memoizes the request builder" do
      expect(client.request_builder).to equal(client.request_builder)
    end
  end

  describe "#redirect_handler" do
    it "returns a redirect handler sharing the connection and request builder" do
      handler = client.redirect_handler

      expect([handler.connection, handler.request_builder]).to eq([client.connection, client.request_builder])
    end

    it "memoizes the redirect handler" do
      expect(client.redirect_handler).to equal(client.redirect_handler)
    end
  end

  describe "#response_parser" do
    it "returns a response parser" do
      expect(client.response_parser).to be_an_instance_of(Gems::ResponseParser)
    end

    it "memoizes the response parser" do
      expect(client.response_parser).to equal(client.response_parser)
    end
  end

  %i[get delete].each do |http_method|
    describe "##{http_method}" do
      it "performs a #{http_method.upcase} request and returns the body" do
        stub_request(http_method, rubygems_url("/path")).to_return(body: "body")

        expect(client.public_send(http_method, "/path")).to eq("body")
      end

      it "sends the data as query parameters" do
        stub_request(http_method, rubygems_url("/path?query=cucumber&page=2"))
        client.public_send(http_method, "/path", {query: "cucumber", page: 2})

        expect(a_request(http_method, rubygems_url("/path?query=cucumber&page=2"))).to have_been_made
      end

      it "does not send a body" do
        stub_request(http_method, rubygems_url("/path?page=2"))
        client.public_send(http_method, "/path", {page: 2}, "application/octet-stream")

        expect(a_request(http_method, rubygems_url("/path?page=2")).with { |request| request.body.nil? || request.body.empty? })
          .to have_been_made
      end

      it "sends a form Content-Type header by default" do
        stub_request(http_method, rubygems_url("/path"))
        client.public_send(http_method, "/path")

        expect(a_request(http_method, rubygems_url("/path"))
          .with(headers: {"Content-Type" => "application/x-www-form-urlencoded"})).to have_been_made
      end

      it "sends the given Content-Type header" do
        stub_request(http_method, rubygems_url("/path"))
        client.public_send(http_method, "/path", {}, "application/json")

        expect(a_request(http_method, rubygems_url("/path")).with(headers: {"Content-Type" => "application/json"})).to have_been_made
      end

      it "uses a custom host" do
        stub_request(http_method, "http://example.com/path")
        client.public_send(http_method, "/path", {}, described_class::FORM_URLENCODED, "http://example.com")

        expect(a_request(http_method, "http://example.com/path")).to have_been_made
      end

      it "defaults to no parameters, a form content type, and the client's host" do
        stub_request(http_method, rubygems_url("/path"))
        allow(client).to receive(:request).and_call_original
        client.public_send(http_method, "/path")

        expect(client).to have_received(:request)
          .with(http_method, "/path", {}, described_class::FORM_URLENCODED, Gems::Configuration::DEFAULT_HOST)
      end
    end
  end

  %i[post put patch].each do |http_method|
    describe "##{http_method}" do
      it "performs a #{http_method.upcase} request and returns the body" do
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

      it "sends multipart fields" do
        stub_request(http_method, rubygems_url("/path"))
        client.public_send(http_method, "/path", [["gem", "data", {filename: "gems.gem"}]], "multipart/form-data")

        expect(a_request(http_method, rubygems_url("/path")).with(headers: {"Content-Type" => "multipart/form-data"}))
          .to have_been_made
      end

      it "sends a Hash as multipart fields when the content type is multipart" do
        stub_request(http_method, rubygems_url("/path"))
        client.public_send(http_method, "/path", {gem: "data"}, "multipart/form-data")

        expect(a_request(http_method, rubygems_url("/path")).with(headers: {"Content-Type" => "multipart/form-data"}))
          .to have_been_made
      end

      it "sends a binary body with the given content type" do
        stub_request(http_method, rubygems_url("/path"))
        client.public_send(http_method, "/path", "data", "application/octet-stream")

        expect(a_request(http_method, rubygems_url("/path"))
          .with(body: "data", headers: {"Content-Type" => "application/octet-stream"})).to have_been_made
      end

      it "uses a custom host" do
        stub_request(http_method, "http://example.com/path")
        client.public_send(http_method, "/path", {}, described_class::FORM_URLENCODED, "http://example.com")

        expect(a_request(http_method, "http://example.com/path")).to have_been_made
      end

      it "defaults to an empty form body, a form content type, and the client's host" do
        stub_request(http_method, rubygems_url("/path"))
        allow(client).to receive(:request).and_call_original
        client.public_send(http_method, "/path")

        expect(client).to have_received(:request)
          .with(http_method, "/path", {}, described_class::FORM_URLENCODED, Gems::Configuration::DEFAULT_HOST)
      end
    end
  end

  describe "#request" do
    it "joins the path with the host" do
      client.host = "http://example.com/"
      stub_request(:get, "http://example.com/path")
      client.get("/path")

      expect(a_request(:get, "http://example.com/path")).to have_been_made
    end

    it "sends the user agent" do
      client.user_agent = "Custom User Agent"
      stub_get("/path")
      client.get("/path")

      expect(a_get("/path").with(headers: {"User-Agent" => "Custom User Agent"})).to have_been_made
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
      stub_get("/api/v1/dependencies?gems=rails,thor")
        .to_return(status: 302, headers: {"Location" => "https://bundler.rubygems.org/api/v1/dependencies?gems=rails,thor"})
      stub_request(:get, "https://bundler.rubygems.org/api/v1/dependencies?gems=rails,thor").to_return(body: fixture("dependencies"))

      expect(client.dependencies("rails", "thor").first[:number]).to eq("3.0.9")
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

    it "raises GemError for other error responses" do
      stub_get("/path").to_return(status: 500, body: "Internal Server Error")

      expect { client.get("/path") }.to raise_error(Gems::GemError, "Internal Server Error")
    end

    it "sends a form body" do
      stub_post("/path")
      client.post("/path", {gem_name: "gems"})

      expect(a_post("/path").with(body: "gem_name=gems", headers: {"Content-Type" => "application/x-www-form-urlencoded"}))
        .to have_been_made
    end

    it "sends a binary body with its content type" do
      stub_post("/path")
      client.post("/path", "data", "application/json")

      expect(a_post("/path").with(body: "data", headers: {"Content-Type" => "application/json"})).to have_been_made
    end

    it "sends a Hash as multipart fields for a multipart content type" do
      stub_post("/path")
      client.post("/path", {gem: "data"}, "multipart/form-data")

      expect(a_post("/path").with(headers: {"Content-Type" => "multipart/form-data"})).to have_been_made
    end

    it "sends the content type without a body" do
      stub_get("/path")
      client.get("/path", {}, "application/json")

      expect(a_get("/path").with(headers: {"Content-Type" => "application/json"})).to have_been_made
    end

    it "performs requests through the connection" do
      stub_get("/path")
      allow(client.connection).to receive(:perform).and_call_original
      client.get("/path")

      expect(client.connection).to have_received(:perform).with(request: an_instance_of(Net::HTTP::Get))
    end
  end

  describe "#body_for" do
    it "converts a Hash to multipart fields for a multipart content type" do
      expect(client.send(:body_for, {gem: "data"}, "multipart/form-data")).to eq([[:gem, "data"]])
    end

    it "keeps a Hash for a form content type" do
      expect(client.send(:body_for, {gem: "data"}, described_class::FORM_URLENCODED)).to eq({gem: "data"})
    end

    it "keeps an Array for a multipart content type" do
      expect(client.send(:body_for, [%w[gem data]], "multipart/form-data")).to eq([%w[gem data]])
    end

    it "keeps a String" do
      expect(client.send(:body_for, "data", "application/octet-stream")).to eq("data")
    end

    it "keeps a String for a multipart content type" do
      expect(client.send(:body_for, "data", "multipart/form-data")).to eq("data")
    end

    it "converts a Hash subclass to multipart fields" do
      hash = Class.new(Hash).new.merge!(gem: "data")

      expect(client.send(:body_for, hash, "multipart/form-data")).to eq([[:gem, "data"]])
    end
  end
end
