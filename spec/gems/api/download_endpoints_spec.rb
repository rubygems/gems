# frozen_string_literal: true

RSpec.describe Gems::API::DownloadEndpoints do
  let(:client) { Gems::Client.new(key: nil, username: nil, password: nil) }

  describe "#total_downloads" do
    before { stub_get("/api/v1/downloads.json").to_return(body: fixture("total_downloads.json")) }

    it "gets the correct resource" do
      client.total_downloads

      expect(a_get("/api/v1/downloads.json")).to have_been_made
    end

    it "returns the total downloads of all gems" do
      expect(client.total_downloads).to eq(244_368_950)
    end

    it "raises InvalidResponse when the response has no total" do
      stub_get("/api/v1/downloads.json").to_return(body: "{}")

      expect { client.total_downloads }.to raise_error(an_instance_of(Gems::InvalidResponse).and(having_attributes(body: "{}")))
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

    it "names the version the downloads were asked for" do
      expect(client.downloads("rails_admin", "0.0.0").full_name).to eq("rails_admin-0.0.0")
    end

    it "names the platform of the version the downloads were asked for" do
      stub_get("/api/v1/downloads/nokogiri-1.15.0-java.json").to_return(body: fixture("rails_admin-0.0.0.json"))

      expect(client.downloads("nokogiri", "1.15.0", platform: "java").full_name).to eq("nokogiri-1.15.0-java")
    end

    it "keeps the full name a response carries of its own" do
      stub_get("/api/v1/downloads/rails_admin-0.0.0.json").to_return(body: '{"full_name":"rails_admin-0.0.0-java"}')

      expect(client.downloads("rails_admin", "0.0.0").full_name).to eq("rails_admin-0.0.0-java")
    end

    it "includes the platform of a version in the full name" do
      stub_get("/api/v1/downloads/nokogiri-1.15.0-java.json").to_return(body: fixture("rails_admin-0.0.0.json"))
      client.downloads("nokogiri", Gems::Version.new("number" => "1.15.0", "platform" => "java"))

      expect(a_get("/api/v1/downloads/nokogiri-1.15.0-java.json")).to have_been_made
    end

    it "accepts a platform" do
      stub_get("/api/v1/downloads/nokogiri-1.15.0-java.json").to_return(body: fixture("rails_admin-0.0.0.json"))
      client.downloads("nokogiri", "1.15.0", platform: "java")

      expect(a_get("/api/v1/downloads/nokogiri-1.15.0-java.json")).to have_been_made
    end

    it "prefers a platform to the platform of a version" do
      stub_get("/api/v1/downloads/nokogiri-1.15.0-java.json").to_return(body: fixture("rails_admin-0.0.0.json"))
      client.downloads("nokogiri", Gems::Version.new("number" => "1.15.0", "platform" => "x86_64-linux"), platform: "java")

      expect(a_get("/api/v1/downloads/nokogiri-1.15.0-java.json")).to have_been_made
    end

    it "escapes the gem name" do
      stub_get("/api/v1/downloads/..%2Frails-0.0.0.json").to_return(body: fixture("rails_admin-0.0.0.json"))
      client.downloads("../rails", "0.0.0")

      expect(a_get("/api/v1/downloads/..%2Frails-0.0.0.json")).to have_been_made
    end

    it "defaults to the latest version" do
      stub_get("/api/v1/versions/rails_admin/latest.json").to_return(body: '{"version":"3.0.9"}')
      stub_get("/api/v1/downloads/rails_admin-3.0.9.json").to_return(body: fixture("rails_admin-0.0.0.json"))
      client.downloads("rails_admin")

      expect(a_get("/api/v1/downloads/rails_admin-3.0.9.json")).to have_been_made
    end

    it "gets the downloads of the version given as the gem" do
      stub_get("/api/v1/downloads/nokogiri-1.15.0-java.json").to_return(body: fixture("rails_admin-0.0.0.json"))
      client.downloads(Gems::Version.new("name" => "nokogiri", "number" => "1.15.0", "platform" => "java"))

      expect(a_get("/api/v1/downloads/nokogiri-1.15.0-java.json")).to have_been_made
    end

    it "gets the downloads of the version a gem carries" do
      stub_get("/api/v1/downloads/nokogiri-1.15.0-java.json").to_return(body: fixture("rails_admin-0.0.0.json"))
      client.downloads(Gems::Gem.new("name" => "nokogiri", "version" => "1.15.0", "platform" => "java"))

      expect(a_get("/api/v1/downloads/nokogiri-1.15.0-java.json")).to have_been_made
    end

    it "falls back to the latest version for a gem that carries none" do
      stub_get("/api/v1/versions/rails_admin/latest.json").to_return(body: '{"version":"3.0.9"}')
      stub_get("/api/v1/downloads/rails_admin-3.0.9.json").to_return(body: fixture("rails_admin-0.0.0.json"))
      client.downloads(Gems::Gem.new("name" => "rails_admin"))

      expect(a_get("/api/v1/downloads/rails_admin-3.0.9.json")).to have_been_made
    end

    it "prefers an explicit version to the version given as the gem" do
      client.downloads(Gems::Version.new("name" => "rails_admin", "number" => "0.0.1"), "0.0.0")

      expect(a_get("/api/v1/downloads/rails_admin-0.0.0.json")).to have_been_made
    end

    it "asks for the downloads of a version by the full name it carries" do
      stub_get("/api/v1/downloads/nokogiri-1.15.0-a1b2c3d4.json").to_return(body: fixture("rails_admin-0.0.0.json"))
      version = Gems::Version.new("name" => "nokogiri", "number" => "1.15.0", "platform" => "x86_64-linux",
        "ruby_abi" => "3.4", "full_name" => "nokogiri-1.15.0-a1b2c3d4")

      expect(client.downloads(version).full_name).to eq("nokogiri-1.15.0-a1b2c3d4")
    end

    it "raises for a version built for a Ruby ABI that carries no full name" do
      version = Gems::Version.new("name" => "nokogiri", "number" => "1.15.0", "platform" => "x86_64-linux", "ruby_abi" => "3.4")

      expect { client.downloads(version) }.to raise_error(ArgumentError, /Ruby ABI 3\.4/)
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

      expect([version.class, version.full_name]).to eq([Gems::Version, "jmespath-1.6.2"])
    end

    it "includes each version's download count" do
      expect(client.most_downloaded.first.downloads_count).to eq(670_252_649)
    end

    it "derives each version's gem name from its full name" do
      expect(client.most_downloaded.first.name).to eq("jmespath")
    end

    it "raises InvalidResponse when the response has no gems" do
      stub_get("/api/v1/downloads/all.json").to_return(body: "{}")

      expect { client.most_downloaded }.to raise_error(an_instance_of(Gems::InvalidResponse).and(having_attributes(body: "{}")))
    end

    it "raises InvalidResponse when a version has no full name" do
      stub_get("/api/v1/downloads/all.json").to_return(body: '{"gems":[[{"number":"1.0.0"},1]]}')

      expect { client.most_downloaded }.to raise_error(Gems::InvalidResponse)
    end

    it "returns each version's checksum in hex" do
      expect(client.most_downloaded.first.sha).to eq("238d774a58723d6c090494c8879b5e9918c19485f7e840f2c1c7532cf84ebcb1")
    end

    it "excludes the platform from the derived gem name" do
      version = {"full_name" => "nokogiri-1.15.0-java", "number" => "1.15.0", "platform" => "java"}
      stub_get("/api/v1/downloads/all.json").to_return(body: JSON.generate("gems" => [[version, 5]]))

      expect(client.most_downloaded.first.name).to eq("nokogiri")
    end
  end
end
