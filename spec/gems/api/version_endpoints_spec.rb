RSpec.describe Gems::API::VersionEndpoints do
  let(:client) { Gems::Client.new(key: nil, username: nil, password: nil) }

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
