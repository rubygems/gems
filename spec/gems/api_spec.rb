RSpec.describe Gems::API do
  let(:client) { Gems::Client.new(key: nil, username: nil, password: nil) }

  describe "#gem" do
    it "accepts a gem" do
      stub_get("/api/v1/gems/rails.json").to_return(body: fixture("rails.json"))
      client.gem(Gems::Gem.new("name" => "rails"))

      expect(a_get("/api/v1/gems/rails.json")).to have_been_made
    end

    context "when the gem exists" do
      before { stub_get("/api/v1/gems/rails.json").to_return(body: fixture("rails.json")) }

      it "gets the correct resource" do
        client.gem("rails")

        expect(a_get("/api/v1/gems/rails.json")).to have_been_made
      end

      it "returns the gem" do
        info = client.gem("rails")

        expect([info.class, info.name]).to eq([Gems::Gem, "rails"])
      end
    end

    context "when the response is not JSON" do
      before { stub_get("/api/v1/gems/nonexistentgem.json").to_return(body: "This rubygem could not be found.") }

      it "raises a parser error" do
        expect { client.gem("nonexistentgem") }.to raise_error(JSON::ParserError)
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
      gem = client.search("cucumber").first

      expect([gem.class, gem.name]).to eq([Gems::Gem, "cucumber"])
    end

    it "passes options as query parameters" do
      client.search("cucumber", page: 2)

      expect(a_get("/api/v1/search.json?query=cucumber&page=2")).to have_been_made
    end
  end

  describe "#autocomplete" do
    before { stub_get("/api/v1/search/autocomplete?query=nokogiri").to_return(body: fixture("autocomplete.json")) }

    it "gets the correct resource" do
      client.autocomplete("nokogiri")

      expect(a_get("/api/v1/search/autocomplete?query=nokogiri")).to have_been_made
    end

    it "returns the gem names that match the query" do
      expect(client.autocomplete("nokogiri")).to eq(%w[nokogiri nokogiri-diff nokogiri-happymapper nokogiri-styles])
    end
  end

  describe "#owned_gems" do
    it "accepts an owner" do
      stub_get("/api/v1/owners/sferik/gems.json").to_return(body: fixture("gems.json"))
      client.owned_gems(Gems::Owner.new("handle" => "sferik"))

      expect(a_get("/api/v1/owners/sferik/gems.json")).to have_been_made
    end

    context "without a user handle" do
      before { stub_get("/api/v1/gems.json").to_return(body: fixture("gems.json")) }

      it "gets the correct resource" do
        client.owned_gems

        expect(a_get("/api/v1/gems.json")).to have_been_made
      end

      it "returns the gems you own" do
        gem = client.owned_gems.first

        expect([gem.class, gem.name]).to eq([Gems::Gem, "exchb"])
      end
    end

    context "with a user handle" do
      before { stub_get("/api/v1/owners/sferik/gems.json").to_return(body: fixture("gems.json")) }

      it "gets the correct resource" do
        client.owned_gems("sferik")

        expect(a_get("/api/v1/owners/sferik/gems.json")).to have_been_made
      end

      it "returns the gems the user owns" do
        gem = client.owned_gems("sferik").first

        expect([gem.class, gem.name]).to eq([Gems::Gem, "exchb"])
      end
    end
  end

  describe "#push" do
    let(:gem) { fixture("gems-0.0.8.gem") }
    let(:gem_data) { File.binread(File.join(fixture_path, "gems-0.0.8.gem")) }

    before { stub_post("/api/v1/gems").to_return(body: fixture("push")) }

    it "posts the gem as a binary body" do
      client.push(gem)

      expect(a_post("/api/v1/gems")
        .with(body: gem_data, headers: {"Content-Type" => "application/octet-stream"})).to have_been_made
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

      it "posts a multipart body" do
        client.push(gem, attestations:)

        expect(a_post("/api/v1/gems").with(headers: {"Content-Type" => "multipart/form-data"})).to have_been_made
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

  describe "#multipart_push_body" do
    let(:gem) { fixture("gems-0.0.8.gem") }
    let(:gem_data) { File.binread(File.join(fixture_path, "gems-0.0.8.gem")) }
    let(:attestations) { [fixture("attestations/one.json"), fixture("attestations/two.json")] }
    let(:body) { client.send(:multipart_push_body, gem, attestations) }

    it "includes the gem with its filename and content type" do
      expect(body.first).to eq(["gem", gem_data, {filename: gem.path, content_type: "application/octet-stream"}])
    end

    it "includes the attestations as a JSON array" do
      expect(body.last).to eq(["attestations", '[{"a":1},{"b":2}]', {content_type: "application/json"}])
    end

    it "has exactly two fields" do
      expect(body.size).to eq(2)
    end
  end

  describe "#yank" do
    before { stub_delete("/api/v1/gems/yank?gem_name=gems&version=0.0.8").to_return(body: fixture("yank")) }

    it "accepts a gem and a version" do
      stub_delete("/api/v1/gems/yank?gem_name=gems&version=0.0.8").to_return(body: fixture("yank"))
      client.yank(Gems::Gem.new("name" => "gems"), Gems::Version.new("number" => "0.0.8"))

      expect(a_delete("/api/v1/gems/yank?gem_name=gems&version=0.0.8")).to have_been_made
    end

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
  end

  describe "#unyank" do
    before { stub_put("/api/v1/gems/unyank").to_return(body: fixture("unyank")) }

    it "accepts a gem and a version" do
      stub_put("/api/v1/gems/unyank").to_return(body: fixture("unyank"))
      client.unyank(Gems::Gem.new("name" => "gems"), Gems::Version.new("number" => "0.0.8"))

      expect(a_put("/api/v1/gems/unyank").with(body: {gem_name: "gems", version: "0.0.8"})).to have_been_made
    end

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
  end

  describe "#versions" do
    before { stub_get("/api/v1/versions/script_helpers.json").to_return(body: fixture("script_helpers.json")) }

    it "accepts a gem" do
      stub_get("/api/v1/versions/script_helpers.json").to_return(body: fixture("script_helpers.json"))
      client.versions(Gems::Gem.new("name" => "script_helpers"))

      expect(a_get("/api/v1/versions/script_helpers.json")).to have_been_made
    end

    it "gets the correct resource" do
      client.versions("script_helpers")

      expect(a_get("/api/v1/versions/script_helpers.json")).to have_been_made
    end

    it "sets each version's gem name" do
      expect(client.versions("script_helpers").map(&:name).uniq).to eq(["script_helpers"])
    end

    it "returns the gem's versions" do
      version = client.versions("script_helpers").first

      expect([version.class, version.number]).to eq([Gems::Version, "0.1.0"])
    end
  end

  describe "#latest_version" do
    before { stub_get("/api/v1/versions/script_helpers/latest.json").to_return(body: fixture("script_helpers/latest.json")) }

    it "accepts a version" do
      stub_get("/api/v1/versions/script_helpers/latest.json").to_return(body: fixture("script_helpers/latest.json"))
      client.latest_version(Gems::Version.new("name" => "script_helpers"))

      expect(a_get("/api/v1/versions/script_helpers/latest.json")).to have_been_made
    end

    it "gets the correct resource" do
      client.latest_version("script_helpers")

      expect(a_get("/api/v1/versions/script_helpers/latest.json")).to have_been_made
    end

    it "returns the gem's latest version number" do
      expect(client.latest_version("script_helpers")).to eq("0.3.0")
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
  end

  describe "#downloads" do
    before { stub_get("/api/v1/downloads/rails_admin-0.0.0.json").to_return(body: fixture("rails_admin-0.0.0.json")) }

    it "accepts a gem and a version" do
      stub_get("/api/v1/downloads/rails_admin-0.0.0.json").to_return(body: fixture("rails_admin-0.0.0.json"))
      client.downloads(Gems::Gem.new("name" => "rails_admin"), Gems::Version.new("number" => "0.0.0"))

      expect(a_get("/api/v1/downloads/rails_admin-0.0.0.json")).to have_been_made
    end

    it "gets the correct resource" do
      client.downloads("rails_admin", "0.0.0")

      expect(a_get("/api/v1/downloads/rails_admin-0.0.0.json")).to have_been_made
    end

    it "returns the gem's downloads" do
      downloads = client.downloads("rails_admin", "0.0.0")

      expect([downloads.class, downloads.total, downloads.version_downloads]).to eq([Gems::Downloads, 3142, 3142])
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
      version = client.most_downloaded.first

      expect([version.class, version.full_name]).to eq([Gems::Version, "abstract-1.0.0"])
    end

    it "includes each version's download count" do
      expect(client.most_downloaded.first.downloads_count).to eq(1)
    end

    it "derives each version's gem name from its full name" do
      expect(client.most_downloaded.first.name).to eq("abstract")
    end

    it "excludes the platform from the derived gem name" do
      version = {"full_name" => "nokogiri-1.15.0-java", "number" => "1.15.0", "platform" => "java"}
      stub_get("/api/v1/downloads/all.json").to_return(body: JSON.generate("gems" => [[version, 5]]))

      expect(client.most_downloaded.first.name).to eq("nokogiri")
    end
  end

  describe "#owners" do
    before { stub_get("/api/v1/gems/gems/owners.json").to_return(body: fixture("owners.json")) }

    it "accepts a gem" do
      stub_get("/api/v1/gems/gems/owners.json").to_return(body: fixture("owners.json"))
      client.owners(Gems::Gem.new("name" => "gems"))

      expect(a_get("/api/v1/gems/gems/owners.json")).to have_been_made
    end

    it "gets the correct resource" do
      client.owners("gems")

      expect(a_get("/api/v1/gems/gems/owners.json")).to have_been_made
    end

    it "returns the gem's owners" do
      owner = client.owners("gems").first

      expect([owner.class, owner.email]).to eq([Gems::Owner, "sferik@gmail.com"])
    end
  end

  describe "#add_owner" do
    before { stub_post("/api/v1/gems/gems/owners").to_return(body: fixture("add_owner")) }

    it "accepts a gem and an owner, using the owner's handle" do
      stub_post("/api/v1/gems/gems/owners").to_return(body: fixture("add_owner"))
      client.add_owner(Gems::Gem.new("name" => "gems"), Gems::Owner.new("handle" => "sferik", "email" => "sferik@gmail.com"))

      expect(a_post("/api/v1/gems/gems/owners").with(body: {email: "sferik"})).to have_been_made
    end

    it "posts the correct resource" do
      client.add_owner("gems", "sferik@gmail.com")

      expect(a_post("/api/v1/gems/gems/owners").with(body: {email: "sferik@gmail.com"})).to have_been_made
    end

    it "posts a role" do
      client.add_owner("gems", "sferik@gmail.com", role: "maintainer")

      expect(a_post("/api/v1/gems/gems/owners").with(body: {email: "sferik@gmail.com", role: "maintainer"})).to have_been_made
    end

    it "returns the response body" do
      expect(client.add_owner("gems", "sferik@gmail.com")).to eq("Owner added successfully.")
    end
  end

  describe "#update_owner" do
    before { stub_request(:patch, rubygems_url("/api/v1/gems/gems/owners")).to_return(body: fixture("update_owner")) }

    it "accepts a gem and an owner, using the owner's handle" do
      client.update_owner(Gems::Gem.new("name" => "gems"), Gems::Owner.new("handle" => "sferik"), role: "maintainer")

      expect(a_request(:patch, rubygems_url("/api/v1/gems/gems/owners"))
        .with(body: {email: "sferik", role: "maintainer"})).to have_been_made
    end

    it "patches the correct resource" do
      client.update_owner("gems", "sferik@gmail.com", role: "maintainer")

      expect(a_request(:patch, rubygems_url("/api/v1/gems/gems/owners"))
        .with(body: {email: "sferik@gmail.com", role: "maintainer"})).to have_been_made
    end

    it "returns the response body" do
      expect(client.update_owner("gems", "sferik@gmail.com", role: "maintainer")).to eq("Owner updated successfully.")
    end
  end

  describe "#remove_owner" do
    before { stub_delete("/api/v1/gems/gems/owners?email=sferik@gmail.com").to_return(body: fixture("remove_owner")) }

    it "accepts a gem and an owner, using the owner's email without a handle" do
      stub_delete("/api/v1/gems/gems/owners?email=sferik@gmail.com").to_return(body: fixture("remove_owner"))
      client.remove_owner(Gems::Gem.new("name" => "gems"), Gems::Owner.new("email" => "sferik@gmail.com"))

      expect(a_delete("/api/v1/gems/gems/owners?email=sferik@gmail.com")).to have_been_made
    end

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

  describe "#latest" do
    before { stub_get("/api/v1/activity/latest.json").to_return(body: fixture("latest.json")) }

    it "gets the correct resource" do
      client.latest

      expect(a_get("/api/v1/activity/latest.json")).to have_been_made
    end

    it "returns the latest gems" do
      gem = client.latest.first

      expect([gem.class, gem.name]).to eq([Gems::Gem, "seanwalbran-rpm_contrib"])
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
      gem = client.just_updated.first

      expect([gem.class, gem.name]).to eq([Gems::Gem, "rspec-tag_matchers"])
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
      api_key = client.create_api_key("ci-push", push_rubygem: true)

      expect([api_key.class, api_key.key]).to eq([Gems::ApiKey, "rubygems_701243f217cdf23b1370c7b66b65ca97"])
    end
  end

  describe "#update_api_key" do
    subject(:client) { Gems::Client.new(key: nil, username: "nick@gemcutter.org", password: "schwwwwing") }

    before { stub_request(:patch, rubygems_url("/api/v1/api_key")).to_return(body: "Scopes for the API key ci-push updated") }

    it "accepts an API key" do
      stub_request(:patch, rubygems_url("/api/v1/api_key")).to_return(body: "Scopes for the API key ci-push updated")
      client.update_api_key(Gems::ApiKey.new("rubygems_api_key" => "rubygems_701243f217cdf23b1370c7b66b65ca97"), yank_rubygem: true)

      expect(a_request(:patch, rubygems_url("/api/v1/api_key"))
        .with(body: {api_key: "rubygems_701243f217cdf23b1370c7b66b65ca97", yank_rubygem: "true"})).to have_been_made
    end

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

    it "returns the exchanged API key" do
      expect(client.exchange_trusted_publisher_token("ID_TOKEN")).to eq(Gems::ApiKey.new(JSON.parse(fixture("exchange_token.json").read)))
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

    it "accepts a gem" do
      stub_get("/api/v1/gems/rspec/reverse_dependencies.json").to_return(body: fixture("reverse_dependencies_short.json"))
      client.reverse_dependencies(Gems::Gem.new("name" => "rspec"))

      expect(a_get("/api/v1/gems/rspec/reverse_dependencies.json")).to have_been_made
    end

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
    it "accepts a gem and a version" do
      stub_get("/api/v2/rubygems/rails/versions/7.0.6.json").to_return(body: fixture("v2/rails-7.0.6.json"))
      client.version(Gems::Gem.new("name" => "rails"), Gems::Version.new("number" => "7.0.6"))

      expect(a_get("/api/v2/rubygems/rails/versions/7.0.6.json")).to have_been_made
    end

    it "requests a specific platform" do
      stub_get("/api/v2/rubygems/rails/versions/7.0.6.json?platform=java").to_return(body: fixture("v2/rails-7.0.6.json"))
      client.version("rails", "7.0.6", platform: "java")

      expect(a_get("/api/v2/rubygems/rails/versions/7.0.6.json?platform=java")).to have_been_made
    end

    it "defaults to the platform of a version" do
      stub_get("/api/v2/rubygems/rails/versions/7.0.6.json?platform=java").to_return(body: fixture("v2/rails-7.0.6.json"))
      client.version("rails", Gems::Version.new("number" => "7.0.6", "platform" => "java"))

      expect(a_get("/api/v2/rubygems/rails/versions/7.0.6.json?platform=java")).to have_been_made
    end

    context "when the gem version exists" do
      before { stub_get("/api/v2/rubygems/rails/versions/7.0.6.json").to_return(body: fixture("v2/rails-7.0.6.json")) }

      it "gets the correct resource" do
        client.version("rails", "7.0.6")

        expect(a_get("/api/v2/rubygems/rails/versions/7.0.6.json")).to have_been_made
      end

      it "returns the gem version" do
        info = client.version("rails", "7.0.6")

        expect([info.class, info.name, info.number]).to eq([Gems::Version, "rails", "7.0.6"])
      end
    end

    context "when the response is not JSON" do
      before { stub_get("/api/v2/rubygems/rails/versions/7.0.99.json").to_return(body: "This version could not be found.") }

      it "raises a parser error" do
        expect { client.version("rails", "7.0.99") }.to raise_error(JSON::ParserError)
      end
    end
  end

  describe "#contents" do
    before { stub_get("/api/v2/rubygems/rails/versions/8.1.3.1/contents.json").to_return(body: fixture("contents.json")) }

    it "accepts a gem and a version" do
      client.contents(Gems::Gem.new("name" => "rails"), Gems::Version.new("number" => "8.1.3.1"))

      expect(a_get("/api/v2/rubygems/rails/versions/8.1.3.1/contents.json")).to have_been_made
    end

    it "gets the correct resource" do
      client.contents("rails", "8.1.3.1")

      expect(a_get("/api/v2/rubygems/rails/versions/8.1.3.1/contents.json")).to have_been_made
    end

    it "requests a specific platform" do
      stub_get("/api/v2/rubygems/rails/versions/8.1.3.1/contents.json?platform=java").to_return(body: fixture("contents.json"))
      client.contents("rails", "8.1.3.1", platform: "java")

      expect(a_get("/api/v2/rubygems/rails/versions/8.1.3.1/contents.json?platform=java")).to have_been_made
    end

    it "defaults to the platform of a version" do
      stub_get("/api/v2/rubygems/rails/versions/8.1.3.1/contents.json?platform=java").to_return(body: fixture("contents.json"))
      client.contents("rails", Gems::Version.new("number" => "8.1.3.1", "platform" => "java"))

      expect(a_get("/api/v2/rubygems/rails/versions/8.1.3.1/contents.json?platform=java")).to have_been_made
    end

    it "returns the checksum of each file" do
      contents = client.contents("rails", "8.1.3.1")

      expect(contents["MIT-LICENSE"]).to eq("sha256" => "717ba1949502290f8e47688ae2e323acd06c8ca47aec9f7596b15f678c1af4a2")
    end
  end

  describe "#attestations" do
    before { stub_get("/api/v1/attestations/rails-8.1.3.1.json").to_return(body: fixture("attestations/rails-8.1.3.1.json")) }

    it "accepts a gem and a version" do
      client.attestations(Gems::Gem.new("name" => "rails"), Gems::Version.new("number" => "8.1.3.1"))

      expect(a_get("/api/v1/attestations/rails-8.1.3.1.json")).to have_been_made
    end

    it "gets the correct resource" do
      client.attestations("rails", "8.1.3.1")

      expect(a_get("/api/v1/attestations/rails-8.1.3.1.json")).to have_been_made
    end

    it "includes a specific platform in the full name" do
      stub_get("/api/v1/attestations/nokogiri-1.15.0-java.json").to_return(body: "[]")
      client.attestations("nokogiri", "1.15.0", platform: "java")

      expect(a_get("/api/v1/attestations/nokogiri-1.15.0-java.json")).to have_been_made
    end

    it "includes the platform of a version in the full name" do
      stub_get("/api/v1/attestations/nokogiri-1.15.0-java.json").to_return(body: "[]")
      client.attestations("nokogiri", Gems::Version.new("number" => "1.15.0", "platform" => "java"))

      expect(a_get("/api/v1/attestations/nokogiri-1.15.0-java.json")).to have_been_made
    end

    it "returns the sigstore bundles" do
      expect(client.attestations("rails", "8.1.3.1").map { |bundle| bundle["mediaType"] })
        .to eq(["application/vnd.dev.sigstore.bundle.v0.3+json"])
    end
  end

  describe "#timeframe_versions" do
    let(:from) { Time.utc(2019, 1, 18, 21, 24, 29) }
    let(:to) { Time.utc(2019, 1, 18, 21, 24, 31) }
    let(:query) { "from=2019-01-18T21:24:29Z&to=2019-01-18T21:24:31Z" }

    before { stub_get("/api/v1/timeframe_versions.json?#{query}").to_return(body: fixture("timeframe_versions.json")) }

    it "gets the correct resource" do
      client.timeframe_versions(from:, to:)

      expect(a_get("/api/v1/timeframe_versions.json?#{query}")).to have_been_made
    end

    it "accepts ISO 8601 strings" do
      client.timeframe_versions(from: "2019-01-18T21:24:29Z", to: "2019-01-18T21:24:31Z")

      expect(a_get("/api/v1/timeframe_versions.json?#{query}")).to have_been_made
    end

    it "defaults the end of the timeframe to now" do
      stub_get("/api/v1/timeframe_versions.json?from=2019-01-18T21:24:29Z").to_return(body: fixture("timeframe_versions.json"))
      client.timeframe_versions(from:)

      expect(a_get("/api/v1/timeframe_versions.json?from=2019-01-18T21:24:29Z")).to have_been_made
    end

    it "requests a page" do
      stub_get("/api/v1/timeframe_versions.json?#{query}&page=2").to_return(body: fixture("timeframe_versions.json"))
      client.timeframe_versions(from:, to:, page: 2)

      expect(a_get("/api/v1/timeframe_versions.json?#{query}&page=2")).to have_been_made
    end

    it "returns the versions created in the timeframe" do
      version = client.timeframe_versions(from:, to:).first

      expect([version.class, version.name, version.version]).to eq([Gems::Gem, "rails", "6.0.0.beta1"])
    end

    it "keeps releases of the same gem distinct" do
      expect(client.timeframe_versions(from:, to:).uniq.map(&:version)).to eq(%w[6.0.0.beta1 6.0.0.beta2])
    end
  end
end
