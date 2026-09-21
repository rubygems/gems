# frozen_string_literal: true

RSpec.describe Gems::TrustedPublisherAuthenticator do
  subject(:authenticator) { described_class.new(id_token: "ID_TOKEN") }

  let(:exchange_url) { "https://rubygems.org/api/v1/oidc/trusted_publisher/exchange_token" }
  let(:request) { Net::HTTP::Get.new("/") }

  def stub_exchange(url = exchange_url)
    stub_request(:post, url).to_return(body: fixture("exchange_token.json"), headers: {"Content-Type" => "application/json"})
  end

  # An exchange the endpoint redirects to another path of the same host, keeping the method and body
  def stub_redirected_exchange(location = "#{exchange_url}/moved")
    stub_request(:post, exchange_url).to_return(status: 308, headers: {"Location" => location})
    stub_exchange(location)
  end

  # An exchange slow enough that concurrent requests reach it together
  def stub_slow_exchange
    stub_request(:post, exchange_url).to_return do
      sleep 0.01
      {body: fixture("exchange_token.json").read, headers: {"Content-Type" => "application/json"}}
    end
  end

  it "is an Authenticator" do
    expect(authenticator).to be_a(Gems::Authenticator)
  end

  describe "#initialize" do
    it "sets the ID token" do
      expect(authenticator.id_token).to eq("ID_TOKEN")
    end

    it "defaults the host" do
      expect(authenticator.host).to eq(Gems::Configuration::DEFAULT_HOST)
    end

    it "defaults the connection" do
      expect(authenticator.connection).to be_an_instance_of(Gems::Connection)
    end

    it "sets a custom host" do
      expect(described_class.new(id_token: "ID_TOKEN", host: "http://example.com").host).to eq("http://example.com")
    end

    it "sets a custom connection" do
      connection = Gems::Connection.new

      expect(described_class.new(id_token: "ID_TOKEN", connection:).connection).to equal(connection)
    end

    it "defaults the request builder" do
      expect(authenticator.request_builder).to be_an_instance_of(Gems::RequestBuilder)
    end

    it "sets a custom request builder" do
      request_builder = Gems::RequestBuilder.new

      expect(described_class.new(id_token: "ID_TOKEN", request_builder:).request_builder).to equal(request_builder)
    end

    it "defaults the redirect handler" do
      expect(authenticator.redirect_handler).to be_an_instance_of(Gems::RedirectHandler)
    end

    it "follows redirects on the connection it was given" do
      connection = Gems::Connection.new

      expect(described_class.new(id_token: "ID_TOKEN", connection:).redirect_handler.connection).to equal(connection)
    end

    it "builds the requests of redirects with the request builder it was given" do
      request_builder = Gems::RequestBuilder.new

      expect(described_class.new(id_token: "ID_TOKEN", request_builder:).redirect_handler.request_builder)
        .to equal(request_builder)
    end

    it "sets a custom redirect handler" do
      redirect_handler = Gems::RedirectHandler.new

      expect(described_class.new(id_token: "ID_TOKEN", redirect_handler:).redirect_handler).to equal(redirect_handler)
    end

    it "builds a mutex, so that concurrent requests exchange the token once" do
      expect(authenticator.instance_variable_get(:@mutex)).to be_an_instance_of(Thread::Mutex)
    end

    it "has no API key before the token is exchanged" do
      expect(authenticator.api_key).to be_nil
    end
  end

  describe "#exchange_token!" do
    before { stub_exchange }

    it "posts the ID token as JSON" do
      authenticator.exchange_token!

      expect(a_request(:post, exchange_url).with(body: '{"jwt":"ID_TOKEN"}',
        headers: {"Content-Type" => "application/json", "Accept" => "application/json"})).to have_been_made
    end

    it "returns the exchanged API key" do
      expect(authenticator.exchange_token!).to eq(Gems::APIKey.new(JSON.parse(fixture("exchange_token.json").read)))
    end

    it "stores the API key" do
      authenticator.exchange_token!

      expect(authenticator.api_key).to eq("rubygems_701243f217cdf23b1370c7b66b65ca97")
    end

    it "exchanges the token with the configured host" do
      stub_exchange("http://example.com/api/v1/oidc/trusted_publisher/exchange_token")
      described_class.new(id_token: "ID_TOKEN", host: "http://example.com").exchange_token!

      expect(a_request(:post, "http://example.com/api/v1/oidc/trusted_publisher/exchange_token")).to have_been_made
    end

    ["https://example.com/gems", "https://example.com/gems/"].each do |host|
      it "preserves the path prefix when the host is #{host}" do
        url = "https://example.com/gems/api/v1/oidc/trusted_publisher/exchange_token"
        stub_exchange(url)
        described_class.new(id_token: "ID_TOKEN", host:).exchange_token!

        expect(a_request(:post, url).with(body: '{"jwt":"ID_TOKEN"}')).to have_been_made.once
      end
    end

    it "uses the configured connection" do
      connection = Gems::Connection.new
      allow(connection).to receive(:perform).and_call_original
      described_class.new(id_token: "ID_TOKEN", connection:).exchange_token!

      expect(connection).to have_received(:perform).with(request: an_instance_of(Net::HTTP::Post))
    end

    it "uses the configured request builder" do
      request_builder = Gems::RequestBuilder.new(user_agent: "Custom User Agent")
      described_class.new(id_token: "ID_TOKEN", request_builder:).exchange_token!

      expect(a_request(:post, exchange_url).with(headers: {"User-Agent" => "Custom User Agent"})).to have_been_made
    end

    it "follows a redirect to the endpoint" do
      stub_redirected_exchange

      expect(authenticator.exchange_token!.key).to eq("rubygems_701243f217cdf23b1370c7b66b65ca97")
    end

    it "sends the ID token and its headers again to where a method-preserving redirect leads" do
      stub_redirected_exchange
      authenticator.exchange_token!

      expect(a_request(:post, "#{exchange_url}/moved").with(body: '{"jwt":"ID_TOKEN"}',
        headers: {"Content-Type" => "application/json", "Accept" => "application/json"})).to have_been_made
    end

    it "follows a redirect to another host without the ID token" do
      stub_request(:post, exchange_url).to_return(status: 303, headers: {"Location" => "https://example.com/exchange"})
      stub_request(:get, "https://example.com/exchange").to_return(body: fixture("exchange_token.json"))
      authenticator.exchange_token!

      expect(a_request(:get, "https://example.com/exchange").with { |request| request.body.nil? }).to have_been_made
    end

    it "uses the configured redirect handler" do
      redirect_handler = Gems::RedirectHandler.new
      allow(redirect_handler).to receive(:handle).and_call_original
      described_class.new(id_token: "ID_TOKEN", redirect_handler:).exchange_token!

      expect(redirect_handler).to have_received(:handle)
    end

    it "raises an HTTPError when the exchange fails" do
      stub_request(:post, exchange_url).to_return(status: 401, body: "Invalid token")

      expect { authenticator.exchange_token! }.to raise_error(Gems::Unauthorized, "Invalid token")
    end

    it "raises InvalidResponse when the exchange answers with a body that is not JSON" do
      stub_request(:post, exchange_url).to_return(body: "<html>")

      expect { authenticator.exchange_token! }.to raise_error(Gems::InvalidResponse)
    end

    it "exchanges the token once when a request is being authenticated at the same time" do
      stub_slow_exchange
      exchanges = [Thread.new { authenticator.exchange_token! }, Thread.new { authenticator.header(request) }]
      exchanges.each(&:join)

      expect(a_request(:post, exchange_url)).to have_been_made.once
    end
  end

  describe "#header" do
    before { stub_exchange }

    it "raises InvalidResponse when the exchange answers without a key" do
      stub_request(:post, exchange_url).to_return(body: '{"name":"ci-push"}')

      expect { authenticator.header(nil) }.to raise_error(Gems::InvalidResponse)
    end

    it "returns an Authorization header with the exchanged API key" do
      expect(authenticator.header(request)).to eq("Authorization" => "rubygems_701243f217cdf23b1370c7b66b65ca97")
    end

    it "exchanges the token only once" do
      authenticator.header(request)
      authenticator.header(request)

      expect(a_request(:post, exchange_url)).to have_been_made.once
    end

    it "reuses a previously exchanged API key" do
      authenticator.exchange_token!
      authenticator.header(request)

      expect(a_request(:post, exchange_url)).to have_been_made.once
    end

    it "exchanges the token only once for concurrent requests" do
      stub_slow_exchange
      Array.new(4) { Thread.new { authenticator.header(request) } }.each(&:join)

      expect(a_request(:post, exchange_url)).to have_been_made.once
    end
  end

  describe "#inspect" do
    it "shows the host without the ID token" do
      expect(authenticator.inspect).to eq('#<Gems::TrustedPublisherAuthenticator host="https://rubygems.org">')
    end
  end
end
