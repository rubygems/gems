RSpec.describe Gems::API::GemEndpoints do
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

    it "accepts a user ID" do
      stub_get("/api/v1/owners/1/gems.json").to_return(body: fixture("gems.json"))
      client.owned_gems(1)

      expect(a_get("/api/v1/owners/1/gems.json")).to have_been_made
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
end
