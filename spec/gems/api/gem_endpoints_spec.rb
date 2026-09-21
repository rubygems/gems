# frozen_string_literal: true

require "pathname"

RSpec.describe Gems::API::GemEndpoints do
  let(:client) { Gems::Client.new(key: nil, username: nil, password: nil) }

  describe "#rubygem" do
    it "accepts a gem" do
      stub_get("/api/v1/gems/rails.json").to_return(body: fixture("rails.json"))
      client.rubygem(Gems::Gem.new("name" => "rails"))

      expect(a_get("/api/v1/gems/rails.json")).to have_been_made
    end

    it "escapes the gem name" do
      stub_get("/api/v1/gems/..%2Frails.json").to_return(body: fixture("rails.json"))
      client.rubygem("../rails")

      expect(a_get("/api/v1/gems/..%2Frails.json")).to have_been_made
    end

    context "when the gem exists" do
      before { stub_get("/api/v1/gems/rails.json").to_return(body: fixture("rails.json")) }

      it "gets the correct resource" do
        client.rubygem("rails")

        expect(a_get("/api/v1/gems/rails.json")).to have_been_made
      end

      it "returns the gem" do
        info = client.rubygem("rails")

        expect([info.class, info.name]).to eq([Gems::Gem, "rails"])
      end
    end

    context "when the response is not JSON" do
      before { stub_get("/api/v1/gems/nonexistentgem.json").to_return(body: "This rubygem could not be found.") }

      it "raises InvalidResponse" do
        expect { client.rubygem("nonexistentgem") }.to raise_error(Gems::InvalidResponse)
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

  describe "#search_each" do
    before do
      stub_get("/api/v1/search.json?query=cucumber&page=1").to_return(body: fixture("search.json"))
      stub_get("/api/v1/search.json?query=cucumber&page=2").to_return(body: "[]")
    end

    it "returns an enumerator" do
      expect(client.search_each("cucumber")).to be_a(Enumerator)
    end

    it "enumerates the gems of every page until one is empty" do
      client.search_each("cucumber").to_a

      expect(a_get("/api/v1/search.json?query=cucumber&page=2")).to have_been_made
    end

    it "returns the gems that match the query" do
      gem = client.search_each("cucumber").first

      expect([gem.class, gem.name]).to eq([Gems::Gem, "cucumber"])
    end

    it "does not request a page the enumeration does not reach" do
      client.search_each("cucumber").first

      expect(a_get("/api/v1/search.json?query=cucumber&page=2")).not_to have_been_made
    end

    it "calls a block with each gem" do
      names = []
      client.search_each("cucumber") { |gem| names << gem.name }

      expect(names.first).to eq("cucumber")
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

    it "escapes the user handle" do
      stub_get("/api/v1/owners/..%2Fsferik/gems.json").to_return(body: fixture("gems.json"))
      client.owned_gems("../sferik")

      expect(a_get("/api/v1/owners/..%2Fsferik/gems.json")).to have_been_made
    end

    it "accepts a user ID" do
      stub_get("/api/v1/owners/1/gems.json").to_return(body: fixture("gems.json"))
      client.owned_gems(1)

      expect(a_get("/api/v1/owners/1/gems.json")).to have_been_made
    end

    it "falls back to the ID of an owner without a handle" do
      stub_get("/api/v1/owners/1/gems.json").to_return(body: fixture("gems.json"))
      client.owned_gems(Gems::Owner.new("id" => 1, "email" => "sferik@gmail.com"))

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

    it "posts a gem given as a path" do
      client.push(File.join(fixture_path, "gems-0.0.8.gem"))

      expect(a_post("/api/v1/gems")
        .with(body: gem_data, headers: {"Content-Type" => "application/octet-stream"})).to have_been_made
    end

    it "posts a gem given as a Pathname" do
      client.push(Pathname(gem.path))

      expect(a_post("/api/v1/gems")
        .with(body: gem_data, headers: {"Content-Type" => "application/octet-stream"})).to have_been_made
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

    it "leaves a gem the caller opened open" do
      client.push(gem)

      expect(gem).not_to be_closed
    end

    it "sends the whole gem again when a redirect preserves the method" do
      stub_post("/api/v1/gems").to_return(status: 307, headers: {"Location" => "/api/v1/gems/push"})
      stub_post("/api/v1/gems/push").to_return(body: fixture("push"))
      client.push(gem)

      expect(a_post("/api/v1/gems/push").with(body: gem_data)).to have_been_made
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

      it "posts a gem given as a path" do
        client.push(File.join(fixture_path, "gems-0.0.8.gem"), attestations:)

        expect(a_post("/api/v1/gems").with(headers: {"Content-Type" => "multipart/form-data"})).to have_been_made
      end

      it "builds the multipart body from the open gem file" do
        allow(client).to receive(:multipart_push_body).and_call_original
        client.push(gem, attestations:)

        expect(client).to have_received(:multipart_push_body).with(gem, attestations)
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

    it "defaults to the platform of a version" do
      stub_delete("/api/v1/gems/yank?gem_name=gems&version=0.0.8&platform=java").to_return(body: fixture("yank"))
      client.yank("gems", Gems::Version.new("number" => "0.0.8", "platform" => "java"))

      expect(a_delete("/api/v1/gems/yank?gem_name=gems&version=0.0.8&platform=java")).to have_been_made
    end

    it "defaults to the latest version" do
      stub_get("/api/v1/versions/gems/latest.json").to_return(body: '{"version":"3.0.9"}')
      stub_delete("/api/v1/gems/yank?gem_name=gems&version=3.0.9").to_return(body: fixture("yank"))
      client.yank("gems")

      expect(a_delete("/api/v1/gems/yank?gem_name=gems&version=3.0.9")).to have_been_made
    end

    it "yanks the version given as the gem" do
      stub_delete("/api/v1/gems/yank?gem_name=gems&version=0.0.8&platform=java").to_return(body: fixture("yank"))
      client.yank(Gems::Version.new("name" => "gems", "number" => "0.0.8", "platform" => "java"))

      expect(a_delete("/api/v1/gems/yank?gem_name=gems&version=0.0.8&platform=java")).to have_been_made
    end

    it "prefers an explicit version to the version given as the gem" do
      client.yank(Gems::Version.new("name" => "gems", "number" => "0.0.7"), "0.0.8")

      expect(a_delete("/api/v1/gems/yank?gem_name=gems&version=0.0.8")).to have_been_made
    end

    it "raises NoLatestVersion when the gem has no published version" do
      stub_get("/api/v1/versions/gems/latest.json").to_return(body: '{"version":"unknown"}')

      expect { client.yank("gems") }.to raise_error(Gems::NoLatestVersion)
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

    it "escapes the gem name" do
      stub_get("/api/v1/gems/..%2Frspec/reverse_dependencies.json").to_return(body: fixture("reverse_dependencies_short.json"))
      client.reverse_dependencies("../rspec")

      expect(a_get("/api/v1/gems/..%2Frspec/reverse_dependencies.json")).to have_been_made
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

  describe "#read_file" do
    let(:path) { File.join(fixture_path, "gems-0.0.8.gem") }

    it "reads a gem given as a path" do
      expect(client.send(:read_file, path)).to eq(File.binread(path))
    end

    it "reads a gem given as a Pathname" do
      expect(client.send(:read_file, Pathname(path))).to eq(File.binread(path))
    end

    it "reads a gem opened in text mode as the bytes it holds" do
      expect(client.send(:read_file, File.new(path))).to eq(File.binread(path))
    end
  end

  describe "#open_file" do
    let(:path) { File.join(fixture_path, "gems-0.0.8.gem") }

    it "opens a gem given as a path" do
      expect(client.send(:open_file, path, &:read)).to eq(File.binread(path))
    end

    it "opens a gem given as a Pathname" do
      expect(client.send(:open_file, Pathname(path), &:read)).to eq(File.binread(path))
    end

    it "closes the file it opens" do
      expect(client.send(:open_file, path) { |file| file }).to be_closed
    end

    it "takes a gem that is already open" do
      file = File.new(path)

      expect(client.send(:open_file, file) { |open| open }).to equal(file)
    end

    it "leaves a gem the caller opened open" do
      file = File.new(path)
      client.send(:open_file, file) { |open| open }

      expect(file).not_to be_closed
    end

    it "reads a gem opened in text mode as the bytes it holds" do
      expect(client.send(:open_file, File.new(path), &:read)).to eq(File.binread(path))
    end

    it "opens a path that begins with a pipe as a file rather than running it" do
      expect { client.send(:open_file, "|echo pushed", &:read) }.to raise_error(Errno::ENOENT)
    end
  end

  describe "#multipart_push_body" do
    let(:gem) { fixture("gems-0.0.8.gem") }
    let(:attestations) { [fixture("attestations/one.json"), fixture("attestations/two.json")] }
    let(:body) { client.send(:multipart_push_body, gem, attestations) }

    it "includes the gem with its filename and content type" do
      expect(body.first).to eq(["gem", gem, {filename: "gems-0.0.8.gem", content_type: "application/octet-stream"}])
    end

    it "sends the name of the gem file rather than the path it was opened with" do
      expect(body.first.last[:filename]).not_to include(File::SEPARATOR)
    end

    it "sends a gem with no path of its own under a name of its own" do
      body = client.send(:multipart_push_body, StringIO.new("gem"), attestations)

      expect(body.first.last[:filename]).to eq("gem")
    end

    it "includes the attestations as a JSON array" do
      expect(body.last).to eq(["attestations", '[{"a":1},{"b":2}]', {content_type: "application/json"}])
    end

    it "has exactly two fields" do
      expect(body.size).to eq(2)
    end

    it "reads the attestations given as paths" do
      paths = %w[one two].map { |name| File.join(fixture_path, "attestations", "#{name}.json") }
      body = client.send(:multipart_push_body, gem, paths)

      expect(body.last).to eq(["attestations", '[{"a":1},{"b":2}]', {content_type: "application/json"}])
    end
  end
end
