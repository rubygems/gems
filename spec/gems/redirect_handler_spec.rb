RSpec.describe Gems::RedirectHandler do
  subject(:handler) { described_class.new(connection:, request_builder:) }

  let(:connection) { Gems::Connection.new }
  let(:request_builder) { Gems::RequestBuilder.new }
  let(:request) { Net::HTTP::Get.new(URI("https://rubygems.org/old")) }

  def redirect(code, location, klass: Net::HTTPFound)
    response = klass.new("1.1", code.to_s, "Redirect")
    response["Location"] = location
    response
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

  describe "#handle" do
    it "returns a non-redirect response unchanged" do
      response = Net::HTTPOK.new("1.1", "200", "OK")

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
      authenticator = Gems::ApiKeyAuthenticator.new(key: TEST_KEY)
      stub_request(:get, "https://rubygems.org/second").to_return(status: 302, headers: {"Location" => "/third"})
      stub_request(:get, "https://rubygems.org/third")
      handler.handle(response: redirect(302, "/second"), request:, authenticator:)

      expect(a_request(:get, "https://rubygems.org/third").with(headers: {"Authorization" => TEST_KEY})).to have_been_made
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
        request = Net::HTTP::Post.new(URI("https://rubygems.org/old"))
        request.form_data = {key: "value"}
        stub_request(:get, "https://rubygems.org/new")
        handler.handle(response: redirect(code, "/new", klass:), request:)

        expect(a_request(:get, "https://rubygems.org/new")).to have_been_made
      end
    end

    it "drops the body on a 302" do
      request = Net::HTTP::Post.new(URI("https://rubygems.org/old"))
      request.form_data = {key: "value"}
      stub_request(:get, "https://rubygems.org/new")
      handler.handle(response: redirect(302, "/new"), request:)

      expect(a_request(:get, "https://rubygems.org/new").with { |req| req.body.nil? || req.body.empty? }).to have_been_made
    end

    {307 => Net::HTTPTemporaryRedirect, 308 => Net::HTTPPermanentRedirect}.each do |code, klass|
      it "preserves the method on a #{code}" do
        request = Net::HTTP::Put.new(URI("https://rubygems.org/old"))
        stub_request(:put, "https://rubygems.org/new")
        handler.handle(response: redirect(code, "/new", klass:), request:)

        expect(a_request(:put, "https://rubygems.org/new")).to have_been_made
      end

      it "preserves the body on a #{code}" do
        request = Net::HTTP::Post.new(URI("https://rubygems.org/old"))
        request.form_data = {key: "value"}
        stub_request(:post, "https://rubygems.org/new")
        handler.handle(response: redirect(code, "/new", klass:), request:)

        expect(a_request(:post, "https://rubygems.org/new").with(body: "key=value")).to have_been_made
      end

      it "preserves authentication on a #{code}" do
        authenticator = Gems::ApiKeyAuthenticator.new(key: TEST_KEY)
        request = Net::HTTP::Post.new(URI("https://rubygems.org/old"))
        stub_request(:post, "https://rubygems.org/new")
        handler.handle(response: redirect(code, "/new", klass:), request:, authenticator:)

        expect(a_request(:post, "https://rubygems.org/new").with(headers: {"Authorization" => TEST_KEY})).to have_been_made
      end

      it "preserves the content type on a #{code}" do
        request = Net::HTTP::Post.new(URI("https://rubygems.org/old"))
        request.form_data = {key: "value"}
        stub_request(:post, "https://rubygems.org/new")
        handler.handle(response: redirect(code, "/new", klass:), request:)

        expect(a_request(:post, "https://rubygems.org/new")
          .with(headers: {"Content-Type" => "application/x-www-form-urlencoded"})).to have_been_made
      end
    end
  end
end
