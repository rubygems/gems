RSpec.describe Gems::API::ProfileEndpoints do
  let(:client) { Gems::Client.new(key: nil, username: nil, password: nil) }

  describe "#profile" do
    before { stub_get("/api/v1/profiles/qrush.json").to_return(body: fixture("profile.json")) }

    it "accepts an owner" do
      client.profile(Gems::Owner.new("handle" => "qrush"))

      expect(a_get("/api/v1/profiles/qrush.json")).to have_been_made
    end

    it "accepts a user ID" do
      stub_get("/api/v1/profiles/1.json").to_return(body: fixture("profile.json"))
      client.profile(1)

      expect(a_get("/api/v1/profiles/1.json")).to have_been_made
    end

    it "gets the correct resource" do
      client.profile("qrush")

      expect(a_get("/api/v1/profiles/qrush.json")).to have_been_made
    end

    it "returns the user's profile" do
      profile = client.profile("qrush")

      expect([profile.class, profile.id, profile.handle, profile.email]).to eq([Gems::Profile, 1, "qrush", "nick@quaran.to"])
    end
  end

  describe "#me" do
    subject(:client) { Gems::Client.new(key: nil, username: "nick@gemcutter.org", password: "schwwwwing") }

    before { stub_get("/api/v1/profile/me.json").to_return(body: fixture("me.json")) }

    it "gets the correct resource with basic authentication" do
      client.me

      expect(a_get("/api/v1/profile/me.json").with(basic_auth: %w[nick@gemcutter.org schwwwwing])).to have_been_made
    end

    it "returns your profile" do
      profile = client.me

      expect([profile.class, profile.handle, profile.mfa]).to eq([Gems::Profile, "qrush", "ui_and_api"])
    end
  end
end
