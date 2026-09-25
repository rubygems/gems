# frozen_string_literal: true

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

    it "falls back to the ID of an owner without a handle" do
      stub_get("/api/v1/profiles/1.json").to_return(body: fixture("profile.json"))
      client.profile(Gems::Owner.new("id" => 1, "email" => "nick@quaran.to"))

      expect(a_get("/api/v1/profiles/1.json")).to have_been_made
    end

    it "gets the correct resource" do
      client.profile("qrush")

      expect(a_get("/api/v1/profiles/qrush.json")).to have_been_made
    end

    it "escapes the user handle" do
      stub_get("/api/v1/profiles/..%2Fqrush.json").to_return(body: fixture("profile.json"))
      client.profile("../qrush")

      expect(a_get("/api/v1/profiles/..%2Fqrush.json")).to have_been_made
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

    it "authenticates with the username and password rather than an API key the client has too" do
      client.key = "rubygems_701243f217cdf23b1370c7b66b65ca97"
      client.me

      expect(a_get("/api/v1/profile/me.json").with(basic_auth: %w[nick@gemcutter.org schwwwwing])).to have_been_made
    end

    it "returns your profile" do
      profile = client.me

      expect([profile.class, profile.handle, profile.mfa]).to eq([Gems::Profile, "qrush", "ui_and_api"])
    end
  end

  describe "#webauthn_verification" do
    subject(:client) { Gems::Client.new(key: TEST_KEY) }

    before { stub_post("/api/v1/webauthn_verification.json").to_return(body: fixture("webauthn_verification.json")) }

    it "posts to the correct resource with the API key" do
      client.webauthn_verification

      expect(a_post("/api/v1/webauthn_verification.json").with(headers: {"Authorization" => TEST_KEY})).to have_been_made
    end

    it "returns the verification" do
      verification = client.webauthn_verification

      expect([verification.class, verification.token]).to eq([Gems::WebAuthnVerification, "odow34b93t6aPCdY"])
    end
  end

  describe "#webauthn_verification_status" do
    subject(:client) { Gems::Client.new(key: TEST_KEY) }

    let(:path) { "/api/v1/webauthn_verification/odow34b93t6aPCdY/status.json" }

    before { stub_get(path).to_return(body: '{"status":"success","code":"123456"}') }

    it "gets the correct resource with the API key" do
      client.webauthn_verification_status("odow34b93t6aPCdY")

      expect(a_get(path).with(headers: {"Authorization" => TEST_KEY})).to have_been_made
    end

    it "accepts a verification" do
      client.webauthn_verification_status(Gems::WebAuthnVerification.new(JSON.parse(fixture("webauthn_verification.json").read)))

      expect(a_get(path)).to have_been_made
    end

    it "escapes the token" do
      stub_get("/api/v1/webauthn_verification/..%2Fx/status.json").to_return(body: '{"status":"not_found"}')
      client.webauthn_verification_status("../x")

      expect(a_get("/api/v1/webauthn_verification/..%2Fx/status.json")).to have_been_made
    end

    it "returns the status, with the one-time passcode" do
      expect(client.webauthn_verification_status("odow34b93t6aPCdY")).to eq("status" => "success", "code" => "123456")
    end
  end
end
