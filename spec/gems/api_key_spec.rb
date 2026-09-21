# frozen_string_literal: true

RSpec.describe Gems::APIKey do
  subject(:api_key) { described_class.new(JSON.parse(fixture("exchange_token.json").read)) }

  it "is a Resource" do
    expect(api_key).to be_a(Gems::Resource)
  end

  describe "::SCOPES" do
    it "names every scope the RubyGems API defines" do
      expect(described_class::SCOPES).to eq(%i[access_webhooks add_owner configure_trusted_publishers
        index_rubygems push_rubygem remove_owner show_dashboard update_owner yank_rubygem])
    end

    it "is frozen, so that a caller cannot change what the endpoints accept" do
      expect(described_class::SCOPES).to be_frozen
    end
  end

  it "inspects as the name and scopes without the key" do
    api_key = described_class.new("rubygems_api_key" => "secret", "name" => "ci-push", "scopes" => ["push_rubygem"])

    expect(api_key.inspect).to eq('#<Gems::APIKey name="ci-push" scopes=["push_rubygem"]>')
  end

  it "exposes the key" do
    expect(api_key.key).to eq("rubygems_701243f217cdf23b1370c7b66b65ca97")
  end

  it "matches a pattern by its key, as it does by the rest of its readers" do
    matched = case api_key
    in {name: String => name, key: String => key} then [name, key]
    end

    expect(matched).to eq([api_key.name, api_key.key])
  end

  it "is identified by its name, so that the key is not compared" do
    other = described_class.new("rubygems_api_key" => "another", "name" => api_key.name)

    expect(api_key).to eq(other)
  end

  it "is not equal to a key of another name" do
    expect(api_key).not_to eq(described_class.new(api_key.to_h.merge("name" => "other")))
  end

  it "raises InvalidResponse without a key" do
    expect { described_class.new({}).key }
      .to raise_error(Gems::InvalidResponse, "The API key response has no rubygems_api_key")
  end

  it "matches a pattern for the rest of its readers without a key, rather than raising" do
    matched = case described_class.new("name" => "ci-push")
    in {name:, **rest} then [name, rest.key?(:key)]
    end

    expect(matched).to eq(["ci-push", false])
  end

  it "does not match a pattern that asks for the key without a key" do
    matched = (described_class.new("name" => "ci-push") in {key: String})

    expect(matched).to be(false)
  end

  it "attaches the attributes as JSON to the error" do
    expect { described_class.new("name" => "ci-push").key }.to raise_error(having_attributes(body: '{"name":"ci-push"}'))
  end

  it "exposes the name" do
    expect(api_key.name).to eq("GitHub Actions rubygems/configure-rubygems-credentials @ .github/workflows/token.yml")
  end

  it "exposes the scopes" do
    expect(api_key.scopes).to eq(["push_rubygem"])
  end

  it "exposes expires_at as a time" do
    expect(api_key.expires_at).to eq(Time.utc(2021, 1, 1))
  end
end
