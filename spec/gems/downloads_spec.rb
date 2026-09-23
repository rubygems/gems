# frozen_string_literal: true

RSpec.describe Gems::Downloads do
  it "is a Resource" do
    expect(described_class.new({})).to be_a(Gems::Resource)
  end

  it "inspects as the version and the totals" do
    expect(described_class.new("full_name" => "rails-8.1.2", "total_downloads" => 3142, "version_downloads" => 42).inspect)
      .to eq("#<Gems::Downloads full_name=\"rails-8.1.2\" total=3142 version_downloads=42>")
  end

  it "is equal to the same counts of the version it names" do
    counts = described_class.new("full_name" => "rails-8.1.2", "version_downloads" => 42)

    expect(counts).to eq(described_class.new("full_name" => "rails-8.1.2", "version_downloads" => 42))
  end

  it "is not equal to other counts of the version it names" do
    counts = described_class.new("full_name" => "rails-8.1.2", "version_downloads" => 42)

    expect(counts).not_to eq(described_class.new("full_name" => "rails-8.1.2", "version_downloads" => 3142))
  end

  it "is not the downloads of another version with the same counts" do
    counts = described_class.new("full_name" => "rails-8.1.2", "version_downloads" => 42)

    expect(counts).not_to eq(described_class.new("full_name" => "rails-8.1.1", "version_downloads" => 42))
  end

  describe "#full_name" do
    it "returns the name and version number of the gem the counts are for" do
      expect(described_class.new("full_name" => "nokogiri-1.15.0-java").full_name).to eq("nokogiri-1.15.0-java")
    end

    it "returns nil for counts that name no version" do
      expect(described_class.new({}).full_name).to be_nil
    end
  end

  describe "#total" do
    it "returns the total downloads of the gem" do
      expect(described_class.new("total_downloads" => 3142).total).to eq(3142)
    end

    it "returns the total downloads of every gem" do
      expect(described_class.new("total" => 3142).total).to eq(3142)
    end

    it "prefers the total of a gem to the total of every gem" do
      expect(described_class.new("total_downloads" => 3142, "total" => 42).total).to eq(3142)
    end

    it "returns nil without total downloads" do
      expect(described_class.new({}).total).to be_nil
    end
  end

  describe "#version_downloads" do
    it "returns the downloads of the version" do
      expect(described_class.new("version_downloads" => 3142).version_downloads).to eq(3142)
    end
  end
end
