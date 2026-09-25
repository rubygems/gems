# frozen_string_literal: true

RSpec.describe Gems::OIDCIDToken do
  subject(:id_token) { described_class.new(JSON.parse(fixture("oidc_id_token.json").read)) }

  it "is a Resource" do
    expect(id_token).to be_a(Gems::Resource)
  end

  it "is identified by all of its attributes" do
    expect(id_token.send(:identity)).to eq(id_token.attributes)
  end

  it "inspects as the token of its role, without its claims" do
    expect(id_token.inspect).to eq('#<Gems::OIDCIDToken api_key_role_token="0123456789abcdef0123456789abcdef">')
  end

  it "exposes the token of its role" do
    expect(id_token.api_key_role_token).to eq("0123456789abcdef0123456789abcdef")
  end

  it "exposes its claims and header" do
    expect(id_token.jwt.keys).to eq(%w[claims header])
  end
end
