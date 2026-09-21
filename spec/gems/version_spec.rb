# frozen_string_literal: true

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
end
