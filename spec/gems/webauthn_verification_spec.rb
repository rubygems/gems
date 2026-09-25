# frozen_string_literal: true

RSpec.describe Gems::WebAuthnVerification do
  subject(:verification) { described_class.new(JSON.parse(fixture("webauthn_verification.json").read)) }

  it "is a Resource" do
    expect(verification).to be_a(Gems::Resource)
  end

  it "inspects as when it expires, without the path that carries its token" do
    expect(verification.inspect).to eq("#<Gems::WebAuthnVerification expires_at=2026-09-25 12:02:00 UTC>")
  end

  it "exposes the path" do
    expect(verification.path).to eq("https://rubygems.org/webauthn_verification/odow34b93t6aPCdY")
  end

  it "parses when it expires" do
    expect(verification.expires_at).to eq(Time.utc(2026, 9, 25, 12, 2))
  end

  it "reads the token from the end of the path" do
    expect(verification.token).to eq("odow34b93t6aPCdY")
  end

  it "has no token without a path" do
    expect(described_class.new({}).token).to be_nil
  end

  it "matches a pattern by its token" do
    matched = case verification
    in {token: String => token} then token
    end

    expect(matched).to eq("odow34b93t6aPCdY")
  end
end
