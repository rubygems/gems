# frozen_string_literal: true

RSpec.describe Gems::API::APIKeyEndpoints do
  let(:client) { Gems::Client.new(key: nil, username: nil, password: nil) }

  # The form fields that grant an API key the scopes given, as the endpoints are sent them
  def scope_fields(*granted)
    Gems::APIKey::SCOPES.to_h { |scope| [scope, granted.include?(scope).to_s] }
  end

  describe "#create_api_key" do
    subject(:client) { Gems::Client.new(key: nil, username: "nick@gemcutter.org", password: "schwwwwing") }

    before { stub_post("/api/v1/api_key.json").to_return(body: fixture("api_key.json")) }

    it "posts the correct resource with basic authentication" do
      client.create_api_key("ci-push", scopes: %i[push_rubygem])

      expect(a_post("/api/v1/api_key.json").with(basic_auth: %w[nick@gemcutter.org schwwwwing],
        body: {name: "ci-push", **scope_fields(:push_rubygem)})).to have_been_made
    end

    it "authenticates with the username and password rather than an API key the client has too" do
      client.key = "rubygems_701243f217cdf23b1370c7b66b65ca97"
      client.create_api_key("ci-push", scopes: %i[push_rubygem])

      expect(a_post("/api/v1/api_key.json").with(basic_auth: %w[nick@gemcutter.org schwwwwing])).to have_been_made
    end

    it "grants every scope it is given" do
      client.create_api_key("ci-push", scopes: %i[push_rubygem yank_rubygem])

      expect(a_post("/api/v1/api_key.json").with(body: {name: "ci-push", **scope_fields(:push_rubygem, :yank_rubygem)}))
        .to have_been_made
    end

    it "accepts the scopes as strings" do
      client.create_api_key("ci-push", scopes: %w[push_rubygem])

      expect(a_post("/api/v1/api_key.json").with(body: {name: "ci-push", **scope_fields(:push_rubygem)})).to have_been_made
    end

    it "accepts one scope on its own" do
      client.create_api_key("ci-push", scopes: :push_rubygem)

      expect(a_post("/api/v1/api_key.json").with(body: {name: "ci-push", **scope_fields(:push_rubygem)})).to have_been_made
    end

    it "grants no scope for an empty list" do
      client.create_api_key("ci-push", scopes: [])

      expect(a_post("/api/v1/api_key.json").with(body: {name: "ci-push", **scope_fields})).to have_been_made
    end

    it "rejects a scope the API does not define" do
      expect { client.create_api_key("ci-push", scopes: %i[push_rubygems]) }
        .to raise_error(ArgumentError, "Unknown API key scope: push_rubygems. The scopes the API defines are: " \
          "access_webhooks, add_owner, configure_trusted_publishers, index_rubygems, push_rubygem, remove_owner, " \
          "show_dashboard, update_owner, yank_rubygem")
    end

    it "reports every scope the API does not define" do
      expect { client.create_api_key("ci-push", scopes: %i[push_rubygem push_rubygems name]) }
        .to raise_error(ArgumentError, /\AUnknown API key scope: push_rubygems, name\./)
    end

    it "does not post a key with a scope the API does not define" do
      client.create_api_key("ci-push", scopes: %i[push_rubygems])
    rescue ArgumentError
      expect(a_post("/api/v1/api_key.json")).not_to have_been_made
    end

    it "posts an expiry, a gem restriction, and a passcode requirement" do
      client.create_api_key("ci-push", scopes: %i[push_rubygem], expires_at: Time.utc(2027, 1, 1),
        rubygem_name: Gems::Gem.new("name" => "gems"), mfa: true)

      body = {name: "ci-push", **scope_fields(:push_rubygem), expires_at: "2027-01-01T00:00:00Z", rubygem_name: "gems",
              mfa: "true"}

      expect(a_post("/api/v1/api_key.json").with(body:)).to have_been_made
    end

    it "accepts an expiry as an ISO 8601 string" do
      client.create_api_key("ci-push", scopes: %i[push_rubygem], expires_at: "2027-01-01T00:00:00Z")

      expect(a_post("/api/v1/api_key.json")
        .with(body: {name: "ci-push", **scope_fields(:push_rubygem), expires_at: "2027-01-01T00:00:00Z"})).to have_been_made
    end

    it "returns the new API key" do
      api_key = client.create_api_key("ci-push", scopes: %i[push_rubygem])

      expect([api_key.class, api_key.key]).to eq([Gems::APIKey, "rubygems_701243f217cdf23b1370c7b66b65ca97"])
    end

    it "keeps the name the key was asked for, which the endpoint answers without" do
      expect(client.create_api_key("ci-push", scopes: %i[push_rubygem]).name).to eq("ci-push")
    end

    it "keeps a name the endpoint answers with" do
      stub_post("/api/v1/api_key.json").to_return(body: JSON.generate("rubygems_api_key" => "key", "name" => "named"))

      expect(client.create_api_key("ci-push", scopes: %i[push_rubygem]).name).to eq("named")
    end
  end

  describe "#update_api_key" do
    subject(:client) { Gems::Client.new(key: nil, username: "nick@gemcutter.org", password: "schwwwwing") }

    before { stub_request(:patch, rubygems_url("/api/v1/api_key")).to_return(body: "Scopes for the API key ci-push updated") }

    it "accepts an API key" do
      client.update_api_key(Gems::APIKey.new("rubygems_api_key" => "rubygems_701243f217cdf23b1370c7b66b65ca97"),
        scopes: %i[yank_rubygem])

      expect(a_request(:patch, rubygems_url("/api/v1/api_key"))
        .with(body: {api_key: "rubygems_701243f217cdf23b1370c7b66b65ca97", **scope_fields(:yank_rubygem)})).to have_been_made
    end

    it "patches the correct resource with basic authentication" do
      client.update_api_key("rubygems_701243f217cdf23b1370c7b66b65ca97", scopes: %i[yank_rubygem])

      expect(a_request(:patch, rubygems_url("/api/v1/api_key")).with(basic_auth: %w[nick@gemcutter.org schwwwwing],
        body: {api_key: "rubygems_701243f217cdf23b1370c7b66b65ca97", **scope_fields(:yank_rubygem)})).to have_been_made
    end

    it "takes away every scope it is not given" do
      client.update_api_key("rubygems_701243f217cdf23b1370c7b66b65ca97", scopes: [])

      expect(a_request(:patch, rubygems_url("/api/v1/api_key"))
        .with(body: {api_key: "rubygems_701243f217cdf23b1370c7b66b65ca97", **scope_fields})).to have_been_made
    end

    it "rejects a scope the API does not define" do
      expect { client.update_api_key("rubygems_701243f217cdf23b1370c7b66b65ca97", scopes: %i[api_key]) }
        .to raise_error(ArgumentError, /\AUnknown API key scope: api_key\./)
    end

    it "does not patch a key with a scope the API does not define" do
      client.update_api_key("rubygems_701243f217cdf23b1370c7b66b65ca97", scopes: %i[yank_rubygems])
    rescue ArgumentError
      expect(a_request(:patch, rubygems_url("/api/v1/api_key"))).not_to have_been_made
    end

    it "returns the response body" do
      expect(client.update_api_key("rubygems_701243f217cdf23b1370c7b66b65ca97", scopes: %i[yank_rubygem]))
        .to eq("Scopes for the API key ci-push updated")
    end
  end

  describe "#api_key_roles" do
    subject(:client) { Gems::Client.new(key: TEST_KEY) }

    before { stub_get("/api/v1/oidc/api_key_roles.json").to_return(body: fixture("api_key_roles.json")) }

    it "gets the roles with the API key" do
      client.api_key_roles

      expect(a_get("/api/v1/oidc/api_key_roles.json").with(headers: {"Authorization" => TEST_KEY})).to have_been_made
    end

    it "returns the roles" do
      expect(client.api_key_roles.map(&:token)).to eq(["0123456789abcdef0123456789abcdef"])
    end
  end

  describe "#api_key_role" do
    subject(:client) { Gems::Client.new(key: TEST_KEY) }

    let(:path) { "/api/v1/oidc/api_key_roles/0123456789abcdef0123456789abcdef.json" }

    before { stub_get(path).to_return(body: fixture("api_key_role.json")) }

    it "gets the role with the API key" do
      client.api_key_role("0123456789abcdef0123456789abcdef")

      expect(a_get(path).with(headers: {"Authorization" => TEST_KEY})).to have_been_made
    end

    it "accepts a role" do
      client.api_key_role(Gems::APIKeyRole.new("token" => "0123456789abcdef0123456789abcdef"))

      expect(a_get(path)).to have_been_made
    end

    it "escapes the token" do
      stub_get("/api/v1/oidc/api_key_roles/..%2Fx.json").to_return(body: fixture("api_key_role.json"))
      client.api_key_role("../x")

      expect(a_get("/api/v1/oidc/api_key_roles/..%2Fx.json")).to have_been_made
    end

    it "returns the role" do
      expect(client.api_key_role("0123456789abcdef0123456789abcdef").name).to eq("Push gems")
    end
  end

  describe "#assume_api_key_role" do
    subject(:client) { Gems::Client.new(key: TEST_KEY) }

    let(:assume_url) { "https://rubygems.org/api/v1/oidc/api_key_roles/0123456789abcdef0123456789abcdef/assume_role.json" }

    before { stub_request(:post, assume_url).to_return(body: fixture("exchange_token.json")) }

    it "posts the ID token as JSON" do
      client.assume_api_key_role("0123456789abcdef0123456789abcdef", "ID_TOKEN")

      expect(a_request(:post, assume_url).with(body: '{"jwt":"ID_TOKEN"}',
        headers: {"Content-Type" => "application/json"})).to have_been_made
    end

    it "sends the exchange without the API key of the client" do
      client.assume_api_key_role("0123456789abcdef0123456789abcdef", "ID_TOKEN")

      expect(a_request(:post, assume_url).with { |request| !request.headers.key?("Authorization") }).to have_been_made
    end

    it "accepts a role" do
      client.assume_api_key_role(Gems::APIKeyRole.new("token" => "0123456789abcdef0123456789abcdef"), "ID_TOKEN")

      expect(a_request(:post, assume_url)).to have_been_made
    end

    it "escapes the token" do
      stub_request(:post, "https://rubygems.org/api/v1/oidc/api_key_roles/..%2Fx/assume_role.json")
        .to_return(body: fixture("exchange_token.json"))
      client.assume_api_key_role("../x", "ID_TOKEN")

      expect(a_request(:post, "https://rubygems.org/api/v1/oidc/api_key_roles/..%2Fx/assume_role.json")).to have_been_made
    end

    it "returns the API key the role issued" do
      expect(client.assume_api_key_role("0123456789abcdef0123456789abcdef", "ID_TOKEN").key)
        .to eq("rubygems_701243f217cdf23b1370c7b66b65ca97")
    end

    it "assumes the role with the client's host" do
      client.host = "http://example.com"
      url = "http://example.com/api/v1/oidc/api_key_roles/0123456789abcdef0123456789abcdef/assume_role.json"
      stub_request(:post, url).to_return(body: fixture("exchange_token.json"))
      client.assume_api_key_role("0123456789abcdef0123456789abcdef", "ID_TOKEN")

      expect(a_request(:post, url)).to have_been_made
    end

    it "uses the client's request builder" do
      client.user_agent = "Custom User Agent"
      client.assume_api_key_role("0123456789abcdef0123456789abcdef", "ID_TOKEN")

      expect(a_request(:post, assume_url).with(headers: {"User-Agent" => "Custom User Agent"})).to have_been_made
    end

    it "follows the redirects of the exchange as far as the client does" do
      client.max_redirects = 0
      stub_request(:post, assume_url).to_return(status: 308, headers: {"Location" => "#{assume_url}/moved"})

      expect { client.assume_api_key_role("0123456789abcdef0123456789abcdef", "ID_TOKEN") }
        .to raise_error(Gems::TooManyRedirects)
    end

    it "uses the client's connection" do
      connection = client.send(:connection)
      allow(connection).to receive(:perform).and_call_original
      client.assume_api_key_role("0123456789abcdef0123456789abcdef", "ID_TOKEN")

      expect(connection).to have_received(:perform).with(request: an_instance_of(Net::HTTP::Post))
    end

    it "sends the exchange again as many times as the client does" do
      client.max_retries = 0
      stub_request(:post, assume_url).to_return(status: 429, headers: {"Retry-After" => "0"})
      client.assume_api_key_role("0123456789abcdef0123456789abcdef", "ID_TOKEN")
    rescue Gems::TooManyRequests
      expect(a_request(:post, assume_url)).to have_been_made.once
    end
  end

  describe "#exchange_trusted_publisher_token" do
    let(:exchange_url) { "https://rubygems.org/api/v1/oidc/trusted_publisher/exchange_token" }

    before { stub_request(:post, exchange_url).to_return(body: fixture("exchange_token.json")) }

    it "posts the ID token as JSON" do
      client.exchange_trusted_publisher_token("ID_TOKEN")

      expect(a_request(:post, exchange_url).with(body: '{"jwt":"ID_TOKEN"}',
        headers: {"Content-Type" => "application/json"})).to have_been_made
    end

    it "returns the exchanged API key" do
      expect(client.exchange_trusted_publisher_token("ID_TOKEN")).to eq(Gems::APIKey.new(JSON.parse(fixture("exchange_token.json").read)))
    end

    it "exchanges the token with the client's host" do
      client.host = "http://example.com"
      stub_request(:post, "http://example.com/api/v1/oidc/trusted_publisher/exchange_token").to_return(body: fixture("exchange_token.json"))
      client.exchange_trusted_publisher_token("ID_TOKEN")

      expect(a_request(:post, "http://example.com/api/v1/oidc/trusted_publisher/exchange_token")).to have_been_made
    end

    it "uses the client's request builder" do
      client.user_agent = "Custom User Agent"
      client.exchange_trusted_publisher_token("ID_TOKEN")

      expect(a_request(:post, exchange_url).with(headers: {"User-Agent" => "Custom User Agent"})).to have_been_made
    end

    it "follows the redirects of the exchange as far as the client does" do
      client.max_redirects = 0
      stub_request(:post, exchange_url).to_return(status: 308, headers: {"Location" => "#{exchange_url}/moved"})

      expect { client.exchange_trusted_publisher_token("ID_TOKEN") }.to raise_error(Gems::TooManyRedirects)
    end

    it "uses the client's connection" do
      connection = client.send(:connection)
      allow(connection).to receive(:perform).and_call_original
      client.exchange_trusted_publisher_token("ID_TOKEN")

      expect(connection).to have_received(:perform).with(request: an_instance_of(Net::HTTP::Post))
    end

    it "sends the exchange again as many times as the client does" do
      client.max_retries = 0
      stub_request(:post, exchange_url).to_return(status: 429, headers: {"Retry-After" => "0"})
      client.exchange_trusted_publisher_token("ID_TOKEN")
    rescue Gems::TooManyRequests
      expect(a_request(:post, exchange_url)).to have_been_made.once
    end
  end
end
