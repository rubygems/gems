RSpec.describe Gems::API do
  let(:client) { Gems::Client.new(key: nil, username: nil, password: nil) }

  describe "#gem" do
    context "when the gem exists" do
      before { stub_get("/api/v1/gems/rails.json").to_return(body: fixture("rails.json")) }

      it "gets the correct resource" do
        client.gem("rails")

        expect(a_get("/api/v1/gems/rails.json")).to have_been_made
      end

      it "returns information about the gem" do
        expect(client.gem("rails")["name"]).to eq("rails")
      end
    end

    context "when the response is not JSON" do
      before { stub_get("/api/v1/gems/nonexistentgem.json").to_return(body: "This rubygem could not be found.") }

      it "returns an empty hash" do
        expect(client.gem("nonexistentgem")).to eq({})
      end
    end
  end

  describe "#search" do
    before do
      stub_get("/api/v1/search.json?query=cucumber").to_return(body: fixture("search.json"))
      stub_get("/api/v1/search.json?query=cucumber&page=2").to_return(body: fixture("search.json"))
    end

    it "gets the correct resource" do
      client.search("cucumber")

      expect(a_get("/api/v1/search.json?query=cucumber")).to have_been_made
    end

    it "returns the gems that match the query" do
      expect(client.search("cucumber").first["name"]).to eq("cucumber")
    end

    it "passes options as query parameters" do
      client.search("cucumber", page: 2)

      expect(a_get("/api/v1/search.json?query=cucumber&page=2")).to have_been_made
    end
  end

  describe "#owned_gems" do
    context "without a user handle" do
      before { stub_get("/api/v1/gems.json").to_return(body: fixture("gems.json")) }

      it "gets the correct resource" do
        client.owned_gems

        expect(a_get("/api/v1/gems.json")).to have_been_made
      end

      it "returns the gems you own" do
        expect(client.owned_gems.first["name"]).to eq("exchb")
      end
    end

    context "with a user handle" do
      before { stub_get("/api/v1/owners/sferik/gems.json").to_return(body: fixture("gems.json")) }

      it "gets the correct resource" do
        client.owned_gems("sferik")

        expect(a_get("/api/v1/owners/sferik/gems.json")).to have_been_made
      end

      it "returns the gems the user owns" do
        expect(client.owned_gems("sferik").first["name"]).to eq("exchb")
      end
    end
  end

  describe "#push" do
    let(:gem) { fixture("gems-0.0.8.gem") }
    let(:gem_data) { File.binread(File.join(fixture_path, "gems-0.0.8.gem")) }

    before do
      stub_post("/api/v1/gems").to_return(body: fixture("push"))
      allow(client).to receive(:post).and_call_original
    end

    it "posts the gem as a binary body" do
      client.push(gem)

      expect(client).to have_received(:post).with("/api/v1/gems", gem_data, host: nil)
    end

    it "returns the response body" do
      expect(client.push(gem)).to eq("Successfully registered gem: gems (0.0.8)")
    end

    it "pushes to the client's host by default" do
      client.host = "http://example.com"
      stub_request(:post, "http://example.com/api/v1/gems").to_return(body: fixture("push"))
      client.push(gem)

      expect(a_request(:post, "http://example.com/api/v1/gems")).to have_been_made
    end

    it "pushes to a custom host" do
      stub_request(:post, "http://example.com/api/v1/gems").to_return(body: fixture("push"))
      client.push(gem, host: "http://example.com")

      expect(a_request(:post, "http://example.com/api/v1/gems")).to have_been_made
    end

    context "with attestations" do
      let(:attestations) { [fixture("attestations/one.json"), fixture("attestations/two.json")] }
      let(:fields) do
        [
          ["gem", gem_data, {filename: gem.path, content_type: "application/octet-stream"}],
          ["attestations", '[{"a":1},{"b":2}]', {content_type: "application/json"}]
        ]
      end

      it "posts multipart fields for the gem and the attestations" do
        client.push(gem, attestations:)

        expect(client).to have_received(:post).with("/api/v1/gems", fields, host: nil)
      end

      it "pushes to a custom host" do
        stub_request(:post, "http://example.com/api/v1/gems").to_return(body: fixture("push"))
        client.push(gem, host: "http://example.com", attestations:)

        expect(a_request(:post, "http://example.com/api/v1/gems")).to have_been_made
      end

      it "returns the response body" do
        expect(client.push(gem, attestations:)).to eq("Successfully registered gem: gems (0.0.8)")
      end
    end
  end

  describe "#yank" do
    before { stub_delete("/api/v1/gems/yank?gem_name=gems&version=0.0.8").to_return(body: fixture("yank")) }

    it "deletes the correct resource" do
      client.yank("gems", "0.0.8")

      expect(a_delete("/api/v1/gems/yank?gem_name=gems&version=0.0.8")).to have_been_made
    end

    it "returns the response body" do
      expect(client.yank("gems", "0.0.8")).to eq("Successfully yanked gem: gems (0.0.8)")
    end

    it "passes options as query parameters" do
      stub_delete("/api/v1/gems/yank?gem_name=gems&version=0.0.8&platform=java").to_return(body: fixture("yank"))
      client.yank("gems", "0.0.8", platform: "java")

      expect(a_delete("/api/v1/gems/yank?gem_name=gems&version=0.0.8&platform=java")).to have_been_made
    end

    it "defaults to the latest version" do
      stub_get("/api/v1/versions/gems/latest.json").to_return(body: '{"version":"3.0.9"}')
      stub_delete("/api/v1/gems/yank?gem_name=gems&version=3.0.9").to_return(body: fixture("yank"))
      client.yank("gems")

      expect(a_delete("/api/v1/gems/yank?gem_name=gems&version=3.0.9")).to have_been_made
    end

    it "raises KeyError when the gem has no version" do
      stub_get("/api/v1/versions/gems/latest.json").to_return(body: "{}")

      expect { client.yank("gems") }.to raise_error(KeyError)
    end
  end

  describe "#unyank" do
    before { stub_put("/api/v1/gems/unyank").to_return(body: fixture("unyank")) }

    it "puts the correct resource" do
      client.unyank("gems", "0.0.8")

      expect(a_put("/api/v1/gems/unyank").with(body: {gem_name: "gems", version: "0.0.8"})).to have_been_made
    end

    it "returns the response body" do
      expect(client.unyank("gems", "0.0.8")).to eq("Successfully unyanked gem: gems (0.0.8)")
    end

    it "passes options in the body" do
      client.unyank("gems", "0.0.8", platform: "java")

      expect(a_put("/api/v1/gems/unyank").with(body: {gem_name: "gems", version: "0.0.8", platform: "java"})).to have_been_made
    end

    it "defaults to the latest version" do
      stub_get("/api/v1/versions/gems/latest.json").to_return(body: '{"version":"3.0.9"}')
      client.unyank("gems")

      expect(a_put("/api/v1/gems/unyank").with(body: {gem_name: "gems", version: "3.0.9"})).to have_been_made
    end

    it "raises KeyError when the gem has no version" do
      stub_get("/api/v1/versions/gems/latest.json").to_return(body: "{}")

      expect { client.unyank("gems") }.to raise_error(KeyError)
    end
  end

  describe "#versions" do
    before { stub_get("/api/v1/versions/script_helpers.json").to_return(body: fixture("script_helpers.json")) }

    it "gets the correct resource" do
      client.versions("script_helpers")

      expect(a_get("/api/v1/versions/script_helpers.json")).to have_been_made
    end

    it "returns the gem's versions" do
      expect(client.versions("script_helpers").first["number"]).to eq("0.1.0")
    end
  end

  describe "#latest_version" do
    before { stub_get("/api/v1/versions/script_helpers/latest.json").to_return(body: fixture("script_helpers/latest.json")) }

    it "gets the correct resource" do
      client.latest_version("script_helpers")

      expect(a_get("/api/v1/versions/script_helpers/latest.json")).to have_been_made
    end

    it "returns the gem's latest version" do
      expect(client.latest_version("script_helpers")).to eq("0.3.0")
    end

    it "raises KeyError when the response has no version" do
      stub_get("/api/v1/versions/script_helpers/latest.json").to_return(body: "{}")

      expect { client.latest_version("script_helpers") }.to raise_error(KeyError)
    end
  end

  describe "#total_downloads" do
    before { stub_get("/api/v1/downloads.json").to_return(body: fixture("total_downloads.json")) }

    it "gets the correct resource" do
      client.total_downloads

      expect(a_get("/api/v1/downloads.json")).to have_been_made
    end

    it "returns the total downloads of all gems" do
      expect(client.total_downloads).to eq(244_368_950)
    end

    it "raises KeyError when the response has no total" do
      stub_get("/api/v1/downloads.json").to_return(body: "{}")

      expect { client.total_downloads }.to raise_error(KeyError)
    end
  end

  describe "#downloads" do
    before { stub_get("/api/v1/downloads/rails_admin-0.0.0.json").to_return(body: fixture("rails_admin-0.0.0.json")) }

    it "gets the correct resource" do
      client.downloads("rails_admin", "0.0.0")

      expect(a_get("/api/v1/downloads/rails_admin-0.0.0.json")).to have_been_made
    end

    it "returns the gem's downloads with symbolized keys" do
      expect(client.downloads("rails_admin", "0.0.0").values_at(:total_downloads, :version_downloads)).to eq([3142, 3142])
    end

    it "defaults to the latest version" do
      stub_get("/api/v1/versions/rails_admin/latest.json").to_return(body: '{"version":"3.0.9"}')
      stub_get("/api/v1/downloads/rails_admin-3.0.9.json").to_return(body: fixture("rails_admin-0.0.0.json"))
      client.downloads("rails_admin")

      expect(a_get("/api/v1/downloads/rails_admin-3.0.9.json")).to have_been_made
    end
  end

  describe "#most_downloaded" do
    before { stub_get("/api/v1/downloads/all.json").to_return(body: fixture("most_downloaded.json")) }

    it "gets the correct resource" do
      client.most_downloaded

      expect(a_get("/api/v1/downloads/all.json")).to have_been_made
    end

    it "returns the most downloaded gem versions" do
      expect(client.most_downloaded.first.first["full_name"]).to eq("abstract-1.0.0")
    end

    it "raises KeyError when the response has no gems" do
      stub_get("/api/v1/downloads/all.json").to_return(body: "{}")

      expect { client.most_downloaded }.to raise_error(KeyError)
    end
  end

  describe "#owners" do
    before { stub_get("/api/v1/gems/gems/owners.json").to_return(body: fixture("owners.json")) }

    it "gets the correct resource" do
      client.owners("gems")

      expect(a_get("/api/v1/gems/gems/owners.json")).to have_been_made
    end

    it "returns the gem's owners" do
      expect(client.owners("gems").first["email"]).to eq("sferik@gmail.com")
    end
  end

  describe "#add_owner" do
    before { stub_post("/api/v1/gems/gems/owners").to_return(body: fixture("add_owner")) }

    it "posts the correct resource" do
      client.add_owner("gems", "sferik@gmail.com")

      expect(a_post("/api/v1/gems/gems/owners").with(body: {email: "sferik@gmail.com"})).to have_been_made
    end

    it "returns the response body" do
      expect(client.add_owner("gems", "sferik@gmail.com")).to eq("Owner added successfully.")
    end
  end

  describe "#remove_owner" do
    before { stub_delete("/api/v1/gems/gems/owners?email=sferik@gmail.com").to_return(body: fixture("remove_owner")) }

    it "deletes the correct resource" do
      client.remove_owner("gems", "sferik@gmail.com")

      expect(a_delete("/api/v1/gems/gems/owners?email=sferik@gmail.com")).to have_been_made
    end

    it "returns the response body" do
      expect(client.remove_owner("gems", "sferik@gmail.com")).to eq("Owner removed successfully.")
    end
  end

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
      expect(client.web_hooks.map { |hook| hook["url"] }).to eq(%w[http://example.com http://example.com/rails])
    end

    it "uses * as the gem name for hooks registered for all gems" do
      expect(client.web_hooks.first["gem_name"]).to eq("*")
    end

    it "uses the gem name for hooks registered for a gem" do
      expect(client.web_hooks.last["gem_name"]).to eq("rails")
    end

    it "keeps the other attributes" do
      expect(client.web_hooks.last["failure_count"]).to eq(1)
    end
  end

  describe "#add_web_hook" do
    before { stub_post("/api/v1/web_hooks").to_return(body: fixture("add_web_hook")) }

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

    it "posts the correct resource" do
      client.fire_web_hook("*", "http://example.com")

      expect(a_post("/api/v1/web_hooks/fire").with(body: {gem_name: "*", url: "http://example.com"})).to have_been_made
    end

    it "returns the response body" do
      expect(client.fire_web_hook("*", "http://example.com"))
        .to eq("Successfully deployed webhook for gemcutter to http://example.com")
    end
  end

  describe "#latest" do
    before { stub_get("/api/v1/activity/latest.json").to_return(body: fixture("latest.json")) }

    it "gets the correct resource" do
      client.latest

      expect(a_get("/api/v1/activity/latest.json")).to have_been_made
    end

    it "returns the latest gems" do
      expect(client.latest.first["name"]).to eq("seanwalbran-rpm_contrib")
    end

    it "passes options as query parameters" do
      stub_get("/api/v1/activity/latest.json?page=2").to_return(body: fixture("latest.json"))
      client.latest(page: 2)

      expect(a_get("/api/v1/activity/latest.json?page=2")).to have_been_made
    end
  end

  describe "#just_updated" do
    before { stub_get("/api/v1/activity/just_updated.json").to_return(body: fixture("just_updated.json")) }

    it "gets the correct resource" do
      client.just_updated

      expect(a_get("/api/v1/activity/just_updated.json")).to have_been_made
    end

    it "returns the most recently updated gems" do
      expect(client.just_updated.first["name"]).to eq("rspec-tag_matchers")
    end

    it "passes options as query parameters" do
      stub_get("/api/v1/activity/just_updated.json?page=2").to_return(body: fixture("just_updated.json"))
      client.just_updated(page: 2)

      expect(a_get("/api/v1/activity/just_updated.json?page=2")).to have_been_made
    end
  end

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

    it "keeps the positional name when the scopes include one" do
      client.create_api_key("ci-push", name: "other")

      expect(a_post("/api/v1/api_key.json").with(body: {name: "ci-push"})).to have_been_made
    end

    it "returns the new API key" do
      expect(client.create_api_key("ci-push", push_rubygem: true)).to eq("rubygems_701243f217cdf23b1370c7b66b65ca97")
    end

    it "raises KeyError when the response has no key" do
      stub_post("/api/v1/api_key.json").to_return(body: "{}")

      expect { client.create_api_key("ci-push") }.to raise_error(KeyError)
    end
  end

  describe "#update_api_key" do
    subject(:client) { Gems::Client.new(key: nil, username: "nick@gemcutter.org", password: "schwwwwing") }

    before { stub_request(:patch, rubygems_url("/api/v1/api_key")).to_return(body: "Scopes for the API key ci-push updated") }

    it "patches the correct resource with basic authentication" do
      client.update_api_key("rubygems_701243f217cdf23b1370c7b66b65ca97", yank_rubygem: true)

      expect(a_request(:patch, rubygems_url("/api/v1/api_key")).with(basic_auth: %w[nick@gemcutter.org schwwwwing],
        body: {api_key: "rubygems_701243f217cdf23b1370c7b66b65ca97", yank_rubygem: "true"})).to have_been_made
    end

    it "keeps the positional key when the scopes include one" do
      client.update_api_key("rubygems_701243f217cdf23b1370c7b66b65ca97", api_key: "other")

      expect(a_request(:patch, rubygems_url("/api/v1/api_key"))
        .with(body: {api_key: "rubygems_701243f217cdf23b1370c7b66b65ca97"})).to have_been_made
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

    it "returns the token exchange response" do
      expect(client.exchange_trusted_publisher_token("ID_TOKEN")).to eq(JSON.parse(fixture("exchange_token.json").read))
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
      connection = client.connection
      allow(connection).to receive(:perform).and_call_original
      client.exchange_trusted_publisher_token("ID_TOKEN")

      expect(connection).to have_received(:perform).with(request: an_instance_of(Net::HTTP::Post))
    end
  end

  describe "#reverse_dependencies" do
    before { stub_get("/api/v1/gems/rspec/reverse_dependencies.json").to_return(body: fixture("reverse_dependencies_short.json")) }

    it "gets the correct resource" do
      client.reverse_dependencies("rspec")

      expect(a_get("/api/v1/gems/rspec/reverse_dependencies.json")).to have_been_made
    end

    it "returns the reverse dependencies" do
      expect(client.reverse_dependencies("rspec")).to be_an_instance_of(Array)
    end

    it "passes options as query parameters" do
      stub_get("/api/v1/gems/rspec/reverse_dependencies.json?only=development")
        .to_return(body: fixture("reverse_dependencies_short.json"))
      client.reverse_dependencies("rspec", only: "development")

      expect(a_get("/api/v1/gems/rspec/reverse_dependencies.json?only=development")).to have_been_made
    end
  end

  describe "#version" do
    context "when the gem version exists" do
      before { stub_get("/api/v2/rubygems/rails/versions/7.0.6.json").to_return(body: fixture("v2/rails-7.0.6.json")) }

      it "gets the correct resource" do
        client.version("rails", "7.0.6")

        expect(a_get("/api/v2/rubygems/rails/versions/7.0.6.json")).to have_been_made
      end

      it "returns information about the gem version" do
        expect(client.version("rails", "7.0.6").values_at("name", "version")).to eq(%w[rails 7.0.6])
      end
    end

    context "when the response is not JSON" do
      before { stub_get("/api/v2/rubygems/rails/versions/7.0.99.json").to_return(body: "This version could not be found.") }

      it "returns an empty hash" do
        expect(client.version("rails", "7.0.99")).to eq({})
      end
    end
  end
end
