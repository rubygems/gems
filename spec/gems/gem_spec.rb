RSpec.describe Gems::Gem do
  subject(:gem) { described_class.new(JSON.parse(fixture("v2/rails-7.0.6.json").read)) }

  it "is a Resource" do
    expect(gem).to be_a(Gems::Resource)
  end

  it "inspects as the name and version" do
    expect(gem.inspect).to eq('#<Gems::Gem name="rails" version="7.0.6">')
  end

  {
    name: "rails",
    version: "7.0.6",
    downloads: 454_392_739,
    version_downloads: 1_492_222,
    platform: "ruby",
    authors: "David Heinemeier Hansson",
    licenses: ["MIT"],
    sha: "5dfbd481a23556ad425fc8541399a129a08ed550f877294b44d0170ca5b9f421",
    project_uri: "https://rubygems.org/gems/rails",
    gem_uri: "https://rubygems.org/gems/rails-7.0.6.gem",
    homepage_uri: "https://rubyonrails.org",
    wiki_uri: nil,
    documentation_uri: "https://api.rubyonrails.org/v7.0.6/",
    mailing_list_uri: "https://discuss.rubyonrails.org/c/rubyonrails-talk",
    source_code_uri: "https://github.com/rails/rails/tree/v7.0.6",
    bug_tracker_uri: "https://github.com/rails/rails/issues",
    changelog_uri: "https://github.com/rails/rails/releases/tag/v7.0.6",
    funding_uri: nil
  }.each do |reader, value|
    it "exposes #{reader}" do
      expect(gem.public_send(reader)).to eq(value)
    end
  end

  it "exposes info" do
    expect(gem.info).to start_with("Ruby on Rails is a full-stack web framework")
  end

  it "exposes metadata" do
    expect(gem.metadata["bug_tracker_uri"]).to eq("https://github.com/rails/rails/issues")
  end

  it "exposes spdx_identifier" do
    expect(described_class.new("spdx_identifier" => "MIT").spdx_identifier).to eq("MIT")
  end

  it "exposes version_created_at as a time" do
    expect(gem.version_created_at).to eq(Time.utc(2023, 6, 29, 20, 57, 24.359r))
  end

  it "exposes yanked?" do
    expect(gem.yanked?).to be(false)
  end

  describe "#runtime_dependencies" do
    it "returns dependencies" do
      expect(gem.runtime_dependencies).to all(be_an_instance_of(Gems::Dependency))
    end

    it "wraps the runtime dependencies" do
      expect(gem.runtime_dependencies.first).to eq(Gems::Dependency.new("name" => "actioncable", "requirements" => "= 7.0.6"))
    end

    it "returns an empty array without dependencies" do
      expect(described_class.new({}).runtime_dependencies).to eq([])
    end

    it "returns an empty array without runtime dependencies" do
      expect(described_class.new("dependencies" => {}).runtime_dependencies).to eq([])
    end
  end

  describe "#development_dependencies" do
    it "wraps the development dependencies" do
      gem = described_class.new("dependencies" => {"development" => [{"name" => "rspec", "requirements" => ">= 3"}]})

      expect(gem.development_dependencies).to eq([Gems::Dependency.new("name" => "rspec", "requirements" => ">= 3")])
    end

    it "returns an empty array when there are none" do
      expect(gem.development_dependencies).to eq([])
    end
  end
end
