# frozen_string_literal: true

RSpec.describe Gems::RedirectHandler do
  subject(:handler) { described_class.new(connection:, request_builder:) }

  let(:connection) { Gems::Connection.new }
  let(:request_builder) { Gems::RequestBuilder.new }
  let(:request) { Net::HTTP::Get.new(URI("https://rubygems.org/old")) }
  let(:form_request) { request_builder.build(http_method: :post, uri: URI("https://rubygems.org/old"), body: form_body) }

  def redirect(code, location, klass: Net::HTTPFound)
    response = klass.new("1.1", code.to_s, "Redirect")
    response["Location"] = location
    response
  end

  def form_body
    {key: "value"}
  end

  def multipart_body
    @multipart_body ||= [["gem", "GEM DATA", {filename: "gems-0.0.8.gem", content_type: "application/octet-stream"}]]
  end

  # The requests the connection performs, which show the multipart fields that WebMock cannot read from a request
  def performed_requests
    requests = []
    allow(connection).to receive(:perform).and_wrap_original do |perform, request:|
      requests << request
      perform.call(request:)
    end
    requests
  end

  describe "#initialize" do
    it "defaults the connection" do
      expect(described_class.new.connection).to be_an_instance_of(Gems::Connection)
    end

    it "defaults the request builder" do
      expect(described_class.new.request_builder).to be_an_instance_of(Gems::RequestBuilder)
    end

    it "defaults the maximum redirects" do
      expect(described_class.new.max_redirects).to eq(described_class::DEFAULT_MAX_REDIRECTS)
    end

    it "sets the connection" do
      expect(handler.connection).to equal(connection)
    end

    it "sets the request builder" do
      expect(handler.request_builder).to equal(request_builder)
    end

    it "sets the maximum redirects" do
      expect(described_class.new(max_redirects: 3).max_redirects).to eq(3)
    end
  end

  describe "#max_redirects=" do
    it "assigns a number of redirects" do
      handler.max_redirects = 3

      expect(handler.max_redirects).to eq(3)
    end

    it "raises for a negative number of redirects" do
      expect { handler.max_redirects = -1 }.to raise_error(ArgumentError, "Invalid max_redirects: -1")
    end

    it "raises for a number of redirects that is not whole" do
      expect { handler.max_redirects = 1.5 }.to raise_error(ArgumentError, "Invalid max_redirects: 1.5")
    end

    it "leaves the maximum as it was after a value it refuses" do
      handler.max_redirects = 3
      handler.max_redirects = -1
    rescue ArgumentError
      expect(handler.max_redirects).to eq(3)
    end

    it "refuses the maximum the handler is built with" do
      expect { described_class.new(max_redirects: -1) }.to raise_error(ArgumentError, "Invalid max_redirects: -1")
    end
  end

  describe "#handle" do
    it "returns a non-redirect response unchanged" do
      response = Net::HTTPOK.new("1.1", "200", "OK")

      expect(handler.handle(response:, request:)).to equal(response)
    end

    it "does not follow the Location header of a successful response" do
      response = Net::HTTPCreated.new("1.1", "201", "Created")
      response["Location"] = "https://rubygems.org/new"

      expect(handler.handle(response:, request:)).to equal(response)
    end

    it "follows an absolute redirect" do
      stub_request(:get, "https://bundler.rubygems.org/new")
      handler.handle(response: redirect(302, "https://bundler.rubygems.org/new"), request:)

      expect(a_request(:get, "https://bundler.rubygems.org/new")).to have_been_made
    end

    it "follows a relative redirect" do
      stub_request(:get, "https://rubygems.org/new")
      handler.handle(response: redirect(302, "/new"), request:)

      expect(a_request(:get, "https://rubygems.org/new")).to have_been_made
    end

    it "returns the final response" do
      stub_request(:get, "https://rubygems.org/new").to_return(body: "final")

      expect(handler.handle(response: redirect(302, "/new"), request:).body).to eq("final")
    end

    it "follows multiple redirects" do
      stub_request(:get, "https://rubygems.org/second").to_return(status: 302, headers: {"Location" => "/third"})
      stub_request(:get, "https://rubygems.org/third")
      handler.handle(response: redirect(302, "/second"), request:)

      expect(a_request(:get, "https://rubygems.org/third")).to have_been_made
    end

    it "preserves authentication across redirects" do
      authenticator = Gems::APIKeyAuthenticator.new(key: TEST_KEY)
      stub_request(:get, "https://rubygems.org/second").to_return(status: 302, headers: {"Location" => "/third"})
      stub_request(:get, "https://rubygems.org/third")
      handler.handle(response: redirect(302, "/second"), request:, authenticator:)

      expect(a_request(:get, "https://rubygems.org/third").with(headers: {"Authorization" => TEST_KEY})).to have_been_made
    end

    it "preserves the headers of the caller across redirects" do
      stub_request(:get, "https://rubygems.org/second").to_return(status: 302, headers: {"Location" => "/third"})
      stub_request(:get, "https://rubygems.org/third")
      handler.handle(response: redirect(302, "/second"), request:, headers: {"X-Trace-Id" => "abc123"})

      expect(a_request(:get, "https://rubygems.org/third")
        .with(headers: {"X-Trace-Id" => "abc123"})).to have_been_made
    end

    context "when a redirect leaves the origin" do
      let(:authenticator) { Gems::OTPAuthenticator.new(authenticator: Gems::APIKeyAuthenticator.new(key: TEST_KEY), otp: "123456") }

      def headers_sent_to(location, uri = location)
        stub_request(:get, uri)
        handler.handle(response: redirect(302, location), request:, authenticator:)
        headers = nil
        expect(a_request(:get, uri).with { |req| headers = req.headers }).to have_been_made
        headers
      end

      it "drops the credentials for another host" do
        expect(headers_sent_to("https://example.com/new").keys).not_to include("Authorization", "Otp")
      end

      it "drops the credentials for another scheme" do
        expect(headers_sent_to("http://rubygems.org/new").keys).not_to include("Authorization", "Otp")
      end

      it "drops the credentials for another scheme on the same port" do
        expect(headers_sent_to("http://rubygems.org:443/new").keys).not_to include("Authorization", "Otp")
      end

      it "drops the credentials for another port" do
        expect(headers_sent_to("https://rubygems.org:8443/new").keys).not_to include("Authorization", "Otp")
      end

      it "keeps the credentials for the same origin spelled in another case" do
        expect(headers_sent_to("HTTPS://RubyGems.org/new", "https://rubygems.org/new")).to include("Authorization" => TEST_KEY, "Otp" => "123456")
      end

      it "keeps the credentials for the same origin with an explicit default port" do
        expect(headers_sent_to("https://rubygems.org:443/new")).to include("Authorization" => TEST_KEY)
      end

      it "drops the headers of the caller for another host" do
        stub_request(:get, "https://example.com/new")
        handler.handle(response: redirect(302, "https://example.com/new"), request:, authenticator:,
          headers: {"X-Trace-Id" => "abc123"})

        expect(a_request(:get, "https://example.com/new").with { |req| !req.headers.key?("X-Trace-Id") }).to have_been_made
      end

      it "follows a redirect that does not keep the body to another host" do
        stub_request(:get, "https://example.com/new")
        handler.handle(response: redirect(302, "https://example.com/new"), request: form_request, body: form_body)

        expect(a_request(:get, "https://example.com/new").with { |req| req.body.nil? || req.body.empty? }).to have_been_made
      end

      it "does not restore the credentials on a redirect back" do
        stub_request(:get, "https://example.com/away").to_return(status: 302, headers: {"Location" => "https://rubygems.org/back"})
        stub_request(:get, "https://rubygems.org/back")
        handler.handle(response: redirect(302, "https://example.com/away"), request:, authenticator:)

        expect(a_request(:get, "https://rubygems.org/back").with { |req| !req.headers.key?("Authorization") }).to have_been_made
      end
    end

    context "when a redirect cannot be followed" do
      it "returns a redirect without a Location header" do
        response = Net::HTTPNotModified.new("1.1", "304", "Not Modified")

        expect(handler.handle(response:, request:)).to equal(response)
      end

      it "returns a redirect whose location is not a valid URL" do
        response = redirect(302, "http://exa mple.com/")

        expect(handler.handle(response:, request:)).to equal(response)
      end

      it "returns a redirect whose location is not an HTTP URL" do
        response = redirect(302, "ftp://rubygems.org/new")

        expect(handler.handle(response:, request:)).to equal(response)
      end

      it "makes no request" do
        handler.handle(response: redirect(302, "ftp://rubygems.org/new"), request:)

        expect(a_request(:any, /.*/)).not_to have_been_made
      end

      it "counts against the maximum redirects first" do
        handler.max_redirects = 0

        expect { handler.handle(response: redirect(302, "ftp://rubygems.org/new"), request:) }
          .to raise_error(Gems::TooManyRedirects)
      end
    end

    it "raises TooManyRedirects after the maximum number of redirects" do
      handler.max_redirects = 2
      stub_request(:get, "https://rubygems.org/loop").to_return(status: 302, headers: {"Location" => "/loop"})

      expect { handler.handle(response: redirect(302, "/loop"), request:) }
        .to raise_error(Gems::TooManyRedirects, "Too many redirects")
    end

    it "follows exactly the maximum number of redirects" do
      handler.max_redirects = 2
      stub_request(:get, "https://rubygems.org/loop").to_return(status: 302, headers: {"Location" => "/loop"})
      handler.handle(response: redirect(302, "/loop"), request:)
    rescue Gems::TooManyRedirects
      expect(a_request(:get, "https://rubygems.org/loop")).to have_been_made.times(2)
    end

    it "raises TooManyRedirects when the redirect count already exceeds the maximum" do
      handler.max_redirects = 2

      expect { handler.handle(response: redirect(302, "/new"), request:, redirect_count: 3) }
        .to raise_error(Gems::TooManyRedirects)
    end

    it "does not follow redirects when the maximum is zero" do
      handler.max_redirects = 0

      expect { handler.handle(response: redirect(302, "/new"), request:) }.to raise_error(Gems::TooManyRedirects)
    end

    {301 => Net::HTTPMovedPermanently, 302 => Net::HTTPFound, 303 => Net::HTTPSeeOther}.each do |code, klass|
      it "converts a POST to a GET on a #{code}" do
        stub_request(:get, "https://rubygems.org/new")
        handler.handle(response: redirect(code, "/new", klass:), request: form_request)

        expect(a_request(:get, "https://rubygems.org/new")).to have_been_made
      end
    end

    it "drops the body on a 302" do
      stub_request(:get, "https://rubygems.org/new")
      handler.handle(response: redirect(302, "/new"), request: form_request, body: form_body)

      expect(a_request(:get, "https://rubygems.org/new").with { |req| req.body.nil? || req.body.empty? }).to have_been_made
    end

    {307 => Net::HTTPTemporaryRedirect, 308 => Net::HTTPPermanentRedirect}.each do |code, klass|
      it "preserves the method on a #{code}" do
        request = Net::HTTP::Put.new(URI("https://rubygems.org/old"))
        stub_request(:put, "https://rubygems.org/new")
        handler.handle(response: redirect(code, "/new", klass:), request:)

        expect(a_request(:put, "https://rubygems.org/new")).to have_been_made
      end

      it "preserves the headers of the caller on a #{code}" do
        stub_request(:post, "https://rubygems.org/new")
        handler.handle(response: redirect(code, "/new", klass:), request: form_request, body: form_body,
          headers: {"X-Trace-Id" => "abc123"})

        expect(a_request(:post, "https://rubygems.org/new")
          .with(headers: {"X-Trace-Id" => "abc123"})).to have_been_made
      end

      it "preserves the body on a #{code}" do
        stub_request(:post, "https://rubygems.org/new")
        handler.handle(response: redirect(code, "/new", klass:), request: form_request, body: form_body)

        expect(a_request(:post, "https://rubygems.org/new").with(body: "key=value")).to have_been_made
      end

      it "preserves a multipart body on a #{code}" do
        request = request_builder.build(http_method: :post, uri: URI("https://rubygems.org/old"), body: multipart_body)
        stub_request(:post, "https://rubygems.org/new")
        requests = performed_requests
        handler.handle(response: redirect(code, "/new", klass:), request:, body: multipart_body)

        expect(requests.last.instance_variable_get(:@body_data)).to equal(multipart_body)
      end

      it "preserves a raw body and its content type on a #{code}" do
        request = request_builder.build(http_method: :put, uri: URI("https://rubygems.org/old"), body: "raw", content_type: "text/plain")
        stub_request(:put, "https://rubygems.org/new")
        handler.handle(response: redirect(code, "/new", klass:), request:, body: "raw", content_type: "text/plain")

        expect(a_request(:put, "https://rubygems.org/new").with(body: "raw", headers: {"Content-Type" => "text/plain"})).to have_been_made
      end

      it "preserves the body across a second #{code}" do
        stub_request(:post, "https://rubygems.org/second").to_return(status: code, headers: {"Location" => "/third"})
        stub_request(:post, "https://rubygems.org/third")
        handler.handle(response: redirect(code, "/second", klass:), request: form_request, body: form_body)

        expect(a_request(:post, "https://rubygems.org/third").with(body: "key=value")).to have_been_made
      end

      it "preserves the content type across a second #{code}" do
        request = request_builder.build(http_method: :put, uri: URI("https://rubygems.org/old"), body: "raw", content_type: "text/plain")
        stub_request(:put, "https://rubygems.org/second").to_return(status: code, headers: {"Location" => "/third"})
        stub_request(:put, "https://rubygems.org/third")
        handler.handle(response: redirect(code, "/second", klass:), request:, body: "raw", content_type: "text/plain")

        expect(a_request(:put, "https://rubygems.org/third").with(body: "raw", headers: {"Content-Type" => "text/plain"})).to have_been_made
      end

      it "preserves authentication on a #{code}" do
        authenticator = Gems::APIKeyAuthenticator.new(key: TEST_KEY)
        request = Net::HTTP::Post.new(URI("https://rubygems.org/old"))
        stub_request(:post, "https://rubygems.org/new")
        handler.handle(response: redirect(code, "/new", klass:), request:, authenticator:)

        expect(a_request(:post, "https://rubygems.org/new").with(headers: {"Authorization" => TEST_KEY})).to have_been_made
      end

      it "preserves the content type on a #{code}" do
        stub_request(:post, "https://rubygems.org/new")
        handler.handle(response: redirect(code, "/new", klass:), request: form_request, body: form_body)

        expect(a_request(:post, "https://rubygems.org/new")
          .with(headers: {"Content-Type" => "application/x-www-form-urlencoded"})).to have_been_made
      end

      context "when a #{code} leaves the origin" do
        it "returns a redirect that would send the body again" do
          response = redirect(code, "https://example.com/new", klass:)

          expect(handler.handle(response:, request: form_request, body: form_body)).to equal(response)
        end

        it "does not send the body to the host the redirect names" do
          stub_request(:post, "https://example.com/new")
          handler.handle(response: redirect(code, "https://example.com/new", klass:), request: form_request,
            body: form_body)

          expect(a_request(:post, "https://example.com/new")).not_to have_been_made
        end

        it "follows a redirect for a request that has no body" do
          stub_request(:get, "https://example.com/new")
          handler.handle(response: redirect(code, "https://example.com/new", klass:), request:)

          expect(a_request(:get, "https://example.com/new")).to have_been_made
        end
      end
    end
  end
end
