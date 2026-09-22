# frozen_string_literal: true

RSpec.describe Gems::Gem do
  subject(:gem) { described_class.new(JSON.parse(fixture("v2/rails-7.0.6.json").read)) }

  it "is a Resource" do
    expect(gem).to be_a(Gems::Resource)
  end

  it "is identified by its name, version, and platform" do
    expect(gem.send(:identity)).to eq(["rails", "7.0.6", "ruby"])
  end

  it "ignores other attributes when comparing" do
    expect(described_class.new("name" => "rails", "downloads" => 1)).to eq(described_class.new("name" => "rails", "downloads" => 2))
  end

  it "distinguishes releases of the same gem" do
    release = described_class.new("name" => "rails", "version" => "7.0.6")

    expect(release).not_to eq(described_class.new("name" => "rails", "version" => "7.0.7"))
  end

  it "inspects as the name and version" do
    expect(gem.inspect).to eq('#<Gems::Gem name="rails" version="7.0.6">')
  end

  {
    name: "rails",
    version: "7.0.6",
    downloads: 790_050_187,
    version_downloads: 4_221_718,
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

  it "exposes spec_sha" do
    expect(described_class.new("spec_sha" => "5b60af49").spec_sha).to eq("5b60af49")
  end

  it "exposes the Ruby ABI a version built for one names" do
    expect(described_class.new("ruby_abi" => "3.4").ruby_abi).to eq("3.4")
  end

  it "exposes no Ruby ABI for a version built for none" do
    expect(gem.ruby_abi).to be_nil
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

  describe "#gem_version" do
    it "returns the version as a Gem::Version" do
      expect(gem.gem_version).to eq(Gem::Version.new("7.0.6"))
    end

    it "returns nil without a version" do
      expect(described_class.new({}).gem_version).to be_nil
    end

    it "returns nil for a version that is not a String" do
      expect(described_class.new("version" => 7).gem_version).to be_nil
    end

    it "reads a version of a class that inherits String, such as a safe buffer" do
      version = Class.new(String).new("7.0.6")

      expect(described_class.new("version" => version).gem_version).to eq(Gem::Version.new("7.0.6"))
    end

    it "returns nil for a version RubyGems cannot read" do
      expect(described_class.new("version" => "not a version").gem_version).to be_nil
    end
  end

  describe "#<=>" do
    def build(version, name: "rails", platform: "ruby")
      described_class.new("name" => name, "version" => version, "platform" => platform)
    end

    it "orders versions as RubyGems orders them, rather than as strings" do
      expect(build("7.0.10") <=> build("7.0.9")).to eq(1)
    end

    it "orders a prerelease before the version it leads to" do
      expect(build("7.0.0.rc1") <=> build("7.0.0")).to eq(-1)
    end

    it "answers with zero for the same gem" do
      same = build("7.0.6")

      expect(same <=> build("7.0.6")).to eq(0)
    end

    it "orders different gems by name" do
      expect(build("1.0.0", name: "rails") <=> build("9.9.9", name: "puma")).to eq(1)
    end

    it "orders gems of the same version by platform" do
      expect(build("7.0.6", platform: "java") <=> build("7.0.6", platform: "ruby")).to eq(-1)
    end

    it "orders a gem without a name before one with a name" do
      expect(described_class.new("version" => "7.0.6") <=> build("7.0.6")).to eq(-1)
    end

    it "orders a gem without a platform before one with a platform" do
      expect(described_class.new("name" => "rails", "version" => "7.0.6") <=> build("7.0.6")).to eq(-1)
    end

    it "orders a gem with a name after one without a name" do
      expect(build("7.0.6") <=> described_class.new("version" => "7.0.6", "platform" => "ruby")).to eq(1)
    end

    it "orders a gem with a platform after one without a platform" do
      expect(build("7.0.6") <=> described_class.new("name" => "rails", "version" => "7.0.6")).to eq(1)
    end

    it "sorts the gems of a response" do
      gems = [build("7.0.9"), build("7.0.10"), build("7.0.0.rc1")]

      expect(gems.sort.map(&:version)).to eq(["7.0.0.rc1", "7.0.9", "7.0.10"])
    end

    it "answers with the latest gem from max" do
      expect([build("7.0.9"), build("7.0.10")].max.version).to eq("7.0.10")
    end

    it "answers with nil for a gem without a version" do
      expect(build("7.0.6") <=> described_class.new({})).to be_nil
    end

    it "answers with nil for a gem of its own without a version" do
      expect(described_class.new({}) <=> build("7.0.6")).to be_nil
    end

    it "answers with nil for two gems without a version, rather than ordering them the same" do
      unversioned = described_class.new({})

      expect(unversioned <=> described_class.new({})).to be_nil
    end

    it "answers with nil for an object that is not a gem" do
      expect(build("7.0.6") <=> Gems::Version.new("name" => "rails", "number" => "7.0.6")).to be_nil
    end

    it "answers with nil for a subclass of gem" do
      expect(build("7.0.6") <=> Class.new(described_class).new("name" => "rails", "version" => "7.0.6")).to be_nil
    end

    it "does not make gems with the same order equal" do
      expect(build("7.0.6")).not_to eq(build("7.0.6", name: "puma"))
    end
  end
end
