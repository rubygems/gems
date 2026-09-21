# frozen_string_literal: true

RSpec.describe Gems::Version do
  subject(:version) { described_class.new(JSON.parse(fixture("v2/rails-7.0.6.json").read)) }

  it "is a Resource" do
    expect(version).to be_a(Gems::Resource)
  end

  it "is identified by its name, number, and platform" do
    expect(version.send(:identity)).to eq(["rails", "7.0.6", "ruby"])
  end

  it "inspects as the name and number" do
    expect(version.inspect).to eq('#<Gems::Version name="rails" number="7.0.6">')
  end

  {
    name: "rails",
    authors: "David Heinemeier Hansson",
    summary: "Full-stack web application framework.",
    downloads_count: 4_221_718,
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

  context "with the field names the downloads endpoint uses" do
    subject(:version) do
      described_class.new("sha256" => "I413SlhyPWwJBJTIh5temRjBlIX36EDywcdTLPhOvLE=", "required_ruby_version" => ">= 3.1.0",
        "required_rubygems_version" => ">= 3.4.0", "yanked_at" => "2023-06-29T20:57:24Z")
    end

    {ruby_version: ">= 3.1.0", rubygems_version: ">= 3.4.0"}.each do |reader, value|
      it "exposes #{reader}" do
        expect(version.public_send(reader)).to eq(value)
      end
    end

    it "exposes yanked?" do
      expect(version.yanked?).to be(true)
    end
  end

  describe ".checksum_attribute" do
    let(:subclass) { Class.new(described_class) { checksum_attribute :cert_sha, "cert_sha", "cert_sha256" } }

    it "defines a reader for the checksum in hex" do
      expect(subclass.new("cert_sha" => "abc").cert_sha).to eq("abc")
    end

    it "decodes the base64 checksum" do
      expect(subclass.new("cert_sha256" => "q83v").cert_sha).to eq("abcdef")
    end

    it "prefers the hex key to the base64 one" do
      expect(subclass.new("cert_sha" => "abc", "cert_sha256" => "q83v").cert_sha).to eq("abc")
    end

    it "returns nil when the response carries neither key" do
      expect(subclass.new("sha" => "abc").cert_sha).to be_nil
    end

    it "records the reader in attribute_names" do
      expect(subclass.attribute_names).to eq([*described_class.attribute_names, :cert_sha])
    end

    it "returns the name of the reader" do
      reader = nil
      Class.new(described_class) { reader = checksum_attribute :cert_sha, "cert_sha", "cert_sha256" }

      expect(reader).to eq(:cert_sha)
    end
  end

  describe "#sha" do
    it "returns the hex sha" do
      expect(version.sha).to eq("5dfbd481a23556ad425fc8541399a129a08ed550f877294b44d0170ca5b9f421")
    end

    it "decodes the base64 sha256 the downloads endpoint returns into the hex sha the other endpoints return" do
      expect(described_class.new("sha256" => "I413SlhyPWwJBJTIh5temRjBlIX36EDywcdTLPhOvLE=").sha)
        .to eq("238d774a58723d6c090494c8879b5e9918c19485f7e840f2c1c7532cf84ebcb1")
    end

    it "returns nil without a checksum" do
      expect(described_class.new({}).sha).to be_nil
    end

    it "returns nil for a nil sha256" do
      expect(described_class.new("sha256" => nil).sha).to be_nil
    end

    it "prefers sha to sha256" do
      expect(described_class.new("sha" => "abc", "sha256" => "q83v").sha).to eq("abc")
    end

    it "prefers a nil sha to sha256" do
      expect(described_class.new("sha" => nil, "sha256" => "q83v").sha).to be_nil
    end

    it "is an attribute for pattern matching" do
      expect(version.deconstruct_keys([:sha])).to eq(sha: "5dfbd481a23556ad425fc8541399a129a08ed550f877294b44d0170ca5b9f421")
    end

    it "raises an InvalidResponse for a sha256 that is not base64" do
      expect { described_class.new("sha256" => "not base64!").sha }
        .to raise_error(Gems::InvalidResponse, '"not base64!" is not a base64-encoded checksum')
    end

    it "raises an InvalidResponse for a sha256 that is not a String" do
      expect { described_class.new("sha256" => 12_345).sha }
        .to raise_error(Gems::InvalidResponse, "12345 is not a base64-encoded checksum")
    end

    it "reports the value that could not be decoded" do
      described_class.new("sha256" => "not base64!").sha
    rescue Gems::InvalidResponse => e
      expect(e.body).to eq("not base64!")
    end

    it "reports a value that is not a String as a String" do
      described_class.new("sha256" => 12_345).sha
    rescue Gems::InvalidResponse => e
      expect(e.body).to eq("12345")
    end
  end

  describe "#spec_sha" do
    it "returns the hex spec_sha" do
      expect(described_class.new("spec_sha" => "5b60af49").spec_sha).to eq("5b60af49")
    end

    it "decodes the base64 spec_sha256 the downloads endpoint returns into hex" do
      expect(described_class.new("spec_sha256" => "I413SlhyPWwJBJTIh5temRjBlIX36EDywcdTLPhOvLE=").spec_sha)
        .to eq("238d774a58723d6c090494c8879b5e9918c19485f7e840f2c1c7532cf84ebcb1")
    end

    it "returns nil without a checksum" do
      expect(described_class.new({}).spec_sha).to be_nil
    end

    it "returns nil for a nil spec_sha256" do
      expect(described_class.new("spec_sha256" => nil).spec_sha).to be_nil
    end

    it "prefers spec_sha to spec_sha256" do
      expect(described_class.new("spec_sha" => "abc", "spec_sha256" => "q83v").spec_sha).to eq("abc")
    end

    it "prefers a nil spec_sha to spec_sha256" do
      expect(described_class.new("spec_sha" => nil, "spec_sha256" => "q83v").spec_sha).to be_nil
    end

    it "reads the checksum of the gemspec rather than the one of the gem file" do
      expect(described_class.new("sha" => "abc", "spec_sha" => "def").spec_sha).to eq("def")
    end

    it "is an attribute for pattern matching" do
      expect(described_class.new("spec_sha" => "5b60af49").deconstruct_keys([:spec_sha])).to eq(spec_sha: "5b60af49")
    end

    it "raises an InvalidResponse for a spec_sha256 that is not base64" do
      expect { described_class.new("spec_sha256" => "not base64!").spec_sha }
        .to raise_error(Gems::InvalidResponse, '"not base64!" is not a base64-encoded checksum')
    end
  end

  describe "#number" do
    it "returns the number" do
      expect(version.number).to eq("7.0.6")
    end

    it "returns nil without a number" do
      expect(described_class.new({}).number).to be_nil
    end
  end

  describe "#gem_version" do
    it "returns the number as a Gem::Version" do
      expect(version.gem_version).to eq(Gem::Version.new("7.0.6"))
    end

    it "returns nil without a number" do
      expect(described_class.new({}).gem_version).to be_nil
    end

    it "returns nil for a number that is not a String" do
      expect(described_class.new("number" => 7).gem_version).to be_nil
    end

    it "reads a number of a class that inherits String, such as a safe buffer" do
      number = Class.new(String).new("7.0.6")

      expect(described_class.new("number" => number).gem_version).to eq(Gem::Version.new("7.0.6"))
    end

    it "returns nil for a number RubyGems cannot read" do
      expect(described_class.new("number" => "not a version").gem_version).to be_nil
    end
  end

  describe "#<=>" do
    def build(number, name: "rails", platform: "ruby")
      described_class.new("name" => name, "number" => number, "platform" => platform)
    end

    it "orders numbers as RubyGems orders them, rather than as strings" do
      expect(build("7.0.10") <=> build("7.0.9")).to eq(1)
    end

    it "orders a prerelease before the version it leads to" do
      expect(build("7.0.0.rc1") <=> build("7.0.0")).to eq(-1)
    end

    it "answers with zero for the same version" do
      same = build("7.0.6")

      expect(same <=> build("7.0.6")).to eq(0)
    end

    it "orders versions of different gems by the name of the gem" do
      expect(build("1.0.0", name: "rails") <=> build("9.9.9", name: "puma")).to eq(1)
    end

    it "orders versions of the same number by platform" do
      expect(build("7.0.6", platform: "java") <=> build("7.0.6", platform: "ruby")).to eq(-1)
    end

    it "orders a version without a name before one with a name" do
      expect(described_class.new("number" => "7.0.6") <=> build("7.0.6")).to eq(-1)
    end

    it "orders a version without a platform before one with a platform" do
      expect(described_class.new("name" => "rails", "number" => "7.0.6") <=> build("7.0.6")).to eq(-1)
    end

    it "orders a version with a name after one without a name" do
      expect(build("7.0.6") <=> described_class.new("number" => "7.0.6", "platform" => "ruby")).to eq(1)
    end

    it "orders a version with a platform after one without a platform" do
      expect(build("7.0.6") <=> described_class.new("name" => "rails", "number" => "7.0.6")).to eq(1)
    end

    it "sorts the versions of a gem" do
      versions = [build("7.0.9"), build("7.0.10"), build("7.0.0.rc1")]

      expect(versions.sort.map(&:number)).to eq(["7.0.0.rc1", "7.0.9", "7.0.10"])
    end

    it "answers with the latest version from max" do
      expect([build("7.0.9"), build("7.0.10")].max.number).to eq("7.0.10")
    end

    it "answers with nil for a version without a number" do
      expect(build("7.0.6") <=> described_class.new({})).to be_nil
    end

    it "answers with nil for a version of its own without a number" do
      expect(described_class.new({}) <=> build("7.0.6")).to be_nil
    end

    it "answers with nil for an object that is not a version" do
      expect(build("7.0.6") <=> Gems::Gem.new("name" => "rails", "version" => "7.0.6")).to be_nil
    end

    it "answers with nil for a subclass of version" do
      expect(build("7.0.6") <=> Class.new(described_class).new("name" => "rails", "number" => "7.0.6")).to be_nil
    end

    it "does not make versions with the same order equal" do
      expect(build("7.0.6")).not_to eq(build("7.0.6", name: "puma"))
    end
  end
end
