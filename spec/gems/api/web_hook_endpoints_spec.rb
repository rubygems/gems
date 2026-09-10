RSpec.describe Gems::API::WebHookEndpoints do
  let(:client) { Gems::Client.new(key: nil, username: nil, password: nil) }

  describe "#web_hooks" do
    before do
      stub_get("/api/v1/web_hooks.json").to_return(body: {
        "all gems" => [{"url" => "http://example.com", "failure_count" => 0}],
        "rails" => [{"url" => "http://example.com/rails", "failure_count" => 1}]
      }.to_json)
    end

    it "gets the correct resource" do
      client.web_hooks

      expect(a_get("/api/v1/web_hooks.json")).to have_been_made
    end

    it "returns every registered web hook" do
      expect(client.web_hooks.map(&:url)).to eq(%w[http://example.com http://example.com/rails])
    end

    it "returns web hooks" do
      expect(client.web_hooks).to all(be_an_instance_of(Gems::WebHook))
    end

    it "uses * as the gem name for hooks registered for all gems" do
      expect(client.web_hooks.first.gem_name).to eq("*")
    end

    it "uses the gem name for hooks registered for a gem" do
      expect(client.web_hooks.last.gem_name).to eq("rails")
    end

    it "keeps the other attributes" do
      expect(client.web_hooks.last.failure_count).to eq(1)
    end
  end

  describe "#add_web_hook" do
    before { stub_post("/api/v1/web_hooks").to_return(body: fixture("add_web_hook")) }

    it "accepts a gem and a web hook" do
      stub_post("/api/v1/web_hooks").to_return(body: fixture("add_web_hook"))
      client.add_web_hook(Gems::Gem.new("name" => "rails"), Gems::WebHook.new("url" => "http://example.com"))

      expect(a_post("/api/v1/web_hooks").with(body: {gem_name: "rails", url: "http://example.com"})).to have_been_made
    end

    it "posts the correct resource" do
      client.add_web_hook("*", "http://example.com")

      expect(a_post("/api/v1/web_hooks").with(body: {gem_name: "*", url: "http://example.com"})).to have_been_made
    end

    it "returns the response body" do
      expect(client.add_web_hook("*", "http://example.com"))
        .to eq("Successfully created webhook for all gems to http://example.com")
    end
  end

  describe "#remove_web_hook" do
    before { stub_delete("/api/v1/web_hooks/remove?gem_name=*&url=http://example.com").to_return(body: fixture("remove_web_hook")) }

    it "accepts a gem and a web hook" do
      stub_delete("/api/v1/web_hooks/remove?gem_name=rails&url=http://example.com").to_return(body: fixture("remove_web_hook"))
      client.remove_web_hook(Gems::Gem.new("name" => "rails"), Gems::WebHook.new("url" => "http://example.com"))

      expect(a_delete("/api/v1/web_hooks/remove?gem_name=rails&url=http://example.com")).to have_been_made
    end

    it "deletes the correct resource" do
      client.remove_web_hook("*", "http://example.com")

      expect(a_delete("/api/v1/web_hooks/remove?gem_name=*&url=http://example.com")).to have_been_made
    end

    it "returns the response body" do
      expect(client.remove_web_hook("*", "http://example.com"))
        .to eq("Successfully removed webhook for all gems to http://example.com")
    end
  end

  describe "#fire_web_hook" do
    before { stub_post("/api/v1/web_hooks/fire").to_return(body: fixture("fire_web_hook")) }

    it "accepts a gem and a web hook" do
      stub_post("/api/v1/web_hooks/fire").to_return(body: fixture("fire_web_hook"))
      client.fire_web_hook(Gems::Gem.new("name" => "rails"), Gems::WebHook.new("url" => "http://example.com"))

      expect(a_post("/api/v1/web_hooks/fire").with(body: {gem_name: "rails", url: "http://example.com"})).to have_been_made
    end

    it "posts the correct resource" do
      client.fire_web_hook("*", "http://example.com")

      expect(a_post("/api/v1/web_hooks/fire").with(body: {gem_name: "*", url: "http://example.com"})).to have_been_made
    end

    it "returns the response body" do
      expect(client.fire_web_hook("*", "http://example.com"))
        .to eq("Successfully deployed webhook for gemcutter to http://example.com")
    end
  end
end
