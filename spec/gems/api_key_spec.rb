RSpec.describe Gems::ApiKey do
  subject(:api_key) { described_class.new(JSON.parse(fixture("exchange_token.json").read)) }

  it "is a Resource" do
    expect(api_key).to be_a(Gems::Resource)
  end

  it "inspects as the name and scopes without the key" do
    api_key = described_class.new("rubygems_api_key" => "secret", "name" => "ci-push", "scopes" => ["push_rubygem"])

    expect(api_key.inspect).to eq('#<Gems::ApiKey name="ci-push" scopes=["push_rubygem"]>')
  end

  it "exposes the key" do
    expect(api_key.key).to eq("rubygems_701243f217cdf23b1370c7b66b65ca97")
  end

  it "raises KeyError without a key" do
    expect { described_class.new({}).key }.to raise_error(KeyError)
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
