RSpec.describe Gems::RequestBuilder do
  subject(:builder) { described_class.new }

  let(:uri) { URI("https://rubygems.org/api/v1/gems/rails.json") }

  describe "#initialize" do
    it "defaults the user agent" do
      expect(builder.user_agent).to eq(Gems::Configuration::DEFAULT_USER_AGENT)
    end

    it "sets a custom user agent" do
      expect(described_class.new(user_agent: "Custom User Agent").user_agent).to eq("Custom User Agent")
    end
  end

  describe "#build" do
    described_class::HTTP_METHODS.each do |http_method, request_class|
      it "builds a #{http_method.upcase} request" do
        expect(builder.build(http_method:, uri:)).to be_an_instance_of(request_class)
      end
    end

    it "raises an ArgumentError for an unsupported HTTP method" do
      expect { builder.build(http_method: :patch, uri:) }.to raise_error(ArgumentError, "Unsupported HTTP method: patch")
    end

    it "sets the request URI" do
      expect(builder.build(http_method: :get, uri:).uri).to eq(uri)
    end

    it "sets the default User-Agent header" do
      expect(builder.build(http_method: :get, uri:)["User-Agent"]).to eq(Gems::Configuration::DEFAULT_USER_AGENT)
    end

    it "uses the configured user agent" do
      builder.user_agent = "Custom User Agent"

      expect(builder.build(http_method: :get, uri:)["User-Agent"]).to eq("Custom User Agent")
    end

    it "adds custom headers" do
      request = builder.build(http_method: :get, uri:, headers: {"X-Custom" => "value"})

      expect(request["X-Custom"]).to eq("value")
    end

    it "lets custom headers override the defaults" do
      request = builder.build(http_method: :get, uri:, headers: {"User-Agent" => "Custom User Agent"})

      expect(request["User-Agent"]).to eq("Custom User Agent")
    end

    it "does not add an Authorization header without an authenticator" do
      expect(builder.build(http_method: :get, uri:)["Authorization"]).to be_nil
    end

    it "adds the authenticator's headers" do
      authenticator = Gems::ApiKeyAuthenticator.new(key: TEST_KEY)

      expect(builder.build(http_method: :get, uri:, authenticator:)["Authorization"]).to eq(TEST_KEY)
    end

    it "passes the request to the authenticator" do
      authenticator = instance_double(Gems::Authenticator)
      allow(authenticator).to receive(:header).and_return({})
      builder.build(http_method: :get, uri:, authenticator:)

      expect(authenticator).to have_received(:header).with(an_instance_of(Net::HTTP::Get))
    end

    context "with query parameters" do
      it "appends the parameters to the URI" do
        request = builder.build(http_method: :get, uri:, params: {query: "cucumber", page: 2})

        expect(request.uri.query).to eq("query=cucumber&page=2")
      end

      it "does not add a query without parameters" do
        expect(builder.build(http_method: :get, uri:).uri.query).to be_nil
      end

      it "does not modify the original URI" do
        builder.build(http_method: :get, uri:, params: {query: "cucumber"})

        expect(uri.query).to be_nil
      end
    end

    context "without a body" do
      it "does not set a body" do
        expect(builder.build(http_method: :post, uri:).body).to be_nil
      end

      it "does not set a content type" do
        expect(builder.build(http_method: :post, uri:).content_type).to be_nil
      end
    end

    context "with a Hash body" do
      let(:request) { builder.build(http_method: :post, uri:, body: {gem_name: "rails", url: "http://example.com"}) }

      it "form-encodes the body" do
        expect(request.body).to eq("gem_name=rails&url=http%3A%2F%2Fexample.com")
      end

      it "sets the content type" do
        expect(request.content_type).to eq("application/x-www-form-urlencoded")
      end
    end

    context "with an Array body" do
      let(:body) { [["gem", "data", {filename: "gems-0.0.8.gem", content_type: "application/octet-stream"}]] }
      let(:request) { builder.build(http_method: :post, uri:, body:) }

      it "sets a multipart content type" do
        expect(request.content_type).to eq("multipart/form-data")
      end

      it "sets the multipart fields" do
        expect(request.instance_variable_get(:@body_data)).to equal(body)
      end
    end

    context "with a String body" do
      it "sets the body" do
        expect(builder.build(http_method: :post, uri:, body: "data").body).to eq("data")
      end

      it "defaults the content type to application/octet-stream" do
        expect(builder.build(http_method: :post, uri:, body: "data").content_type).to eq("application/octet-stream")
      end

      it "uses the given content type" do
        request = builder.build(http_method: :post, uri:, body: "{}", content_type: "application/json")

        expect(request.content_type).to eq("application/json")
      end
    end
  end
end
