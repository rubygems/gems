# frozen_string_literal: true

RSpec.describe Gems::APIKeyRole do
  subject(:role) { described_class.new(JSON.parse(fixture("api_key_role.json").read)) }

  it "summarizes the role by its name and token" do
    expect(role.inspect).to eq('#<Gems::APIKeyRole name="Push gems" token="0123456789abcdef0123456789abcdef">')
  end

  it "reads the ID of the role" do
    expect(role.id).to eq(1)
  end

  it "reads the ID of the provider of the role" do
    expect(role.provider_id).to eq(1)
  end

  it "reads the permissions of the keys the role issues" do
    expect(role.api_key_permissions["scopes"]).to eq(["push_rubygem"])
  end

  it "reads the access policy of the role" do
    expect(role.access_policy["statements"].first["effect"]).to eq("allow")
  end

  it "parses when the role was created" do
    expect(role.created_at).to eq(Time.utc(2026, 9, 1, 12))
  end

  it "parses when the role was last updated" do
    expect(role.updated_at).to eq(Time.utc(2026, 9, 2, 12))
  end

  it "is identified by its token" do
    expect(role).to eq(described_class.new(role.to_h.merge("name" => "renamed")))
  end

  it "is not equal to a role of another token" do
    expect(role).not_to eq(described_class.new(role.to_h.merge("token" => "fedcba9876543210fedcba9876543210")))
  end
end
