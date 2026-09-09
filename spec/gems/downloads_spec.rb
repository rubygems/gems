RSpec.describe Gems::Downloads do
  it "is a Resource" do
    expect(described_class.new({})).to be_a(Gems::Resource)
  end

  it "inspects as the totals" do
    expect(described_class.new("total_downloads" => 3142, "version_downloads" => 42).inspect)
      .to eq("#<Gems::Downloads total=3142 version_downloads=42>")
  end

  describe "#total" do
    it "returns the total downloads of the gem" do
      expect(described_class.new("total_downloads" => 3142).total).to eq(3142)
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
