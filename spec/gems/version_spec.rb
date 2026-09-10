RSpec.describe Gems::Version do
  subject(:version) { described_class.new(JSON.parse(fixture("v2/rails-7.0.6.json").read)) }

  it "is a Resource" do
    expect(version).to be_a(Gems::Resource)
  end

  it "is identified by its name, number, and platform" do
    expect(version.identity).to eq(["rails", "7.0.6", "ruby"])
  end

  it "inspects as the name and number" do
    expect(version.inspect).to eq('#<Gems::Version name="rails" number="7.0.6">')
  end

  {
    name: "rails",
    authors: "David Heinemeier Hansson",
    summary: "Full-stack web application framework.",
    downloads_count: 1_492_222,
    platform: "ruby",
    licenses: ["MIT"],
    requirements: [],
    ruby_version: ">= 2.7.0",
    rubygems_version: ">= 1.8.11",
    sha: "5dfbd481a23556ad425fc8541399a129a08ed550f877294b44d0170ca5b9f421"
  }.each do |reader, value|
    it "exposes #{reader}" do
      expect(version.public_send(reader)).to eq(value)
    end
  end

  it "exposes description" do
    expect(version.description).to start_with("Ruby on Rails is a full-stack web framework")
  end

  it "exposes metadata" do
    expect(version.metadata["changelog_uri"]).to eq("https://github.com/rails/rails/releases/tag/v7.0.6")
  end

  it "exposes full_name" do
    expect(described_class.new("full_name" => "abstract-1.0.0").full_name).to eq("abstract-1.0.0")
  end

  it "exposes spdx_identifier" do
    expect(described_class.new("spdx_identifier" => "MIT").spdx_identifier).to eq("MIT")
  end

  it "exposes built_at as a time" do
    expect(version.built_at).to eq(Time.utc(2023, 6, 29))
  end

  it "exposes created_at as a time" do
    expect(version.created_at).to eq(Time.utc(2023, 6, 29, 20, 57, 24.359r))
  end

  it "exposes prerelease?" do
    expect(version.prerelease?).to be(false)
  end

  it "exposes yanked?" do
    expect(version.yanked?).to be(false)
  end

  describe "#number" do
    it "returns the number" do
      expect(version.number).to eq("7.0.6")
    end

    it "returns nil without a number" do
      expect(described_class.new({}).number).to be_nil
    end
  end
end
