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
end
