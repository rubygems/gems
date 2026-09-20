RSpec.describe Gems::API::APIKeyEndpoints do
  let(:client) { Gems::Client.new(key: nil, username: nil, password: nil) }

  describe "#create_api_key" do
    subject(:client) { Gems::Client.new(key: nil, username: "nick@gemcutter.org", password: "schwwwwing") }

    before { stub_post("/api/v1/api_key.json").to_return(body: fixture("api_key.json")) }

    it "posts the correct resource with basic authentication" do
      client.create_api_key("ci-push", push_rubygem: true)

      expect(a_post("/api/v1/api_key.json").with(basic_auth: %w[nick@gemcutter.org schwwwwing],
        body: {name: "ci-push", push_rubygem: "true"})).to have_been_made
    end

    it "posts the name without options" do
      client.create_api_key("ci-push")

      expect(a_post("/api/v1/api_key.json").with(body: {name: "ci-push"})).to have_been_made
    end

    it "rejects a scope the API does not define" do
      expect { client.create_api_key("ci-push", push_rubygems: true) }
        .to raise_error(ArgumentError, "Unknown API key scope: push_rubygems. The scopes the API defines are: " \
          "access_webhooks, add_owner, configure_trusted_publishers, index_rubygems, push_rubygem, remove_owner, " \
          "show_dashboard, update_owner, yank_rubygem")
    end

    it "reports every scope the API does not define" do
      expect { client.create_api_key("ci-push", push_rubygems: true, name: "other") }
        .to raise_error(ArgumentError, /\AUnknown API key scope: push_rubygems, name\./)
    end

    it "does not post a key with a scope the API does not define" do
      client.create_api_key("ci-push", push_rubygems: true)
    rescue ArgumentError
      expect(a_post("/api/v1/api_key.json")).not_to have_been_made
    end

    it "posts an expiry, a gem restriction, and a passcode requirement" do
      client.create_api_key("ci-push", expires_at: Time.utc(2027, 1, 1), rubygem_name: Gems::Gem.new("name" => "gems"), mfa: true)

      expect(a_post("/api/v1/api_key.json")
        .with(body: {name: "ci-push", expires_at: "2027-01-01T00:00:00Z", rubygem_name: "gems", mfa: "true"})).to have_been_made
    end

    it "accepts an expiry as an ISO 8601 string" do
      client.create_api_key("ci-push", expires_at: "2027-01-01T00:00:00Z")

      expect(a_post("/api/v1/api_key.json").with(body: {name: "ci-push", expires_at: "2027-01-01T00:00:00Z"})).to have_been_made
    end

    it "posts scopes alongside settings" do
      client.create_api_key("ci-push", push_rubygem: true, mfa: true)

      expect(a_post("/api/v1/api_key.json")
        .with(body: {name: "ci-push", push_rubygem: "true", mfa: "true"})).to have_been_made
    end

    it "returns the new API key" do
      api_key = client.create_api_key("ci-push", push_rubygem: true)

      expect([api_key.class, api_key.key]).to eq([Gems::APIKey, "rubygems_701243f217cdf23b1370c7b66b65ca97"])
    end
  end

  describe "#update_api_key" do
    subject(:client) { Gems::Client.new(key: nil, username: "nick@gemcutter.org", password: "schwwwwing") }

    before { stub_request(:patch, rubygems_url("/api/v1/api_key")).to_return(body: "Scopes for the API key ci-push updated") }

    it "accepts an API key" do
      stub_request(:patch, rubygems_url("/api/v1/api_key")).to_return(body: "Scopes for the API key ci-push updated")
      client.update_api_key(Gems::APIKey.new("rubygems_api_key" => "rubygems_701243f217cdf23b1370c7b66b65ca97"), yank_rubygem: true)

      expect(a_request(:patch, rubygems_url("/api/v1/api_key"))
        .with(body: {api_key: "rubygems_701243f217cdf23b1370c7b66b65ca97", yank_rubygem: "true"})).to have_been_made
    end

    it "patches the correct resource with basic authentication" do
      client.update_api_key("rubygems_701243f217cdf23b1370c7b66b65ca97", yank_rubygem: true)

      expect(a_request(:patch, rubygems_url("/api/v1/api_key")).with(basic_auth: %w[nick@gemcutter.org schwwwwing],
        body: {api_key: "rubygems_701243f217cdf23b1370c7b66b65ca97", yank_rubygem: "true"})).to have_been_made
    end

    it "rejects a scope the API does not define" do
      expect { client.update_api_key("rubygems_701243f217cdf23b1370c7b66b65ca97", api_key: "other") }
        .to raise_error(ArgumentError, /\AUnknown API key scope: api_key\./)
    end

    it "does not patch a key with a scope the API does not define" do
      client.update_api_key("rubygems_701243f217cdf23b1370c7b66b65ca97", yank_rubygems: true)
    rescue ArgumentError
      expect(a_request(:patch, rubygems_url("/api/v1/api_key"))).not_to have_been_made
    end

    it "returns the response body" do
      expect(client.update_api_key("rubygems_701243f217cdf23b1370c7b66b65ca97")).to eq("Scopes for the API key ci-push updated")
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

    it "uses the client's connection" do
      connection = client.send(:connection)
      allow(connection).to receive(:perform).and_call_original
      client.exchange_trusted_publisher_token("ID_TOKEN")

      expect(connection).to have_received(:perform).with(request: an_instance_of(Net::HTTP::Post))
    end
  end
end
