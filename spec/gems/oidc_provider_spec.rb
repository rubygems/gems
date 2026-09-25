# frozen_string_literal: true

RSpec.describe Gems::OIDCProvider do
  subject(:provider) { described_class.new(JSON.parse(fixture("oidc_provider.json").read)) }

  it "is a Resource" do
    expect(provider).to be_a(Gems::Resource)
  end

  it "is identified by its ID" do
    expect(provider.send(:identity)).to eq([1])
  end

  it "inspects as the ID and issuer" do
    expect(provider.inspect).to eq('#<Gems::OIDCProvider id=1 issuer="https://token.actions.githubusercontent.com">')
  end

  it "exposes the ID" do
    expect(provider.id).to eq(1)
  end

  it "exposes the issuer" do
    expect(provider.issuer).to eq("https://token.actions.githubusercontent.com")
  end

  it "exposes the configuration" do
    expect(provider.configuration["jwks_uri"]).to eq("https://token.actions.githubusercontent.com/.well-known/jwks")
  end

  it "exposes the key set" do
    expect(provider.jwks["keys"].first["kid"]).to eq("1F2AB83404C08EC9EA0BB99DAED02186B091DBF4")
  end

  it "parses when it was added" do
    expect(provider.created_at).to eq(Time.utc(2023, 8, 1))
  end

  it "parses when it was last updated" do
    expect(provider.updated_at).to eq(Time.utc(2026, 9, 1))
  end
end
