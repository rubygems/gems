# Described by name because RSpec would otherwise use Gems::Version.to_s as the description
RSpec.describe "Gems::Version" do
  describe ".to_s" do
    it "joins the major, minor, and patch versions" do
      expect(Gems::Version.to_s)
        .to eq("#{Gems::Version::MAJOR}.#{Gems::Version::MINOR}.#{Gems::Version::PATCH}")
    end

    it "appends the prerelease version when present" do
      stub_const("Gems::Version::PRE", "rc1")

      expect(Gems::Version.to_s).to eq("#{Gems::Version::MAJOR}.#{Gems::Version::MINOR}.#{Gems::Version::PATCH}.rc1")
    end

    it "returns a valid gem version" do
      expect(Gem::Version.correct?(Gems::Version.to_s)).to be(true)
    end
  end

  describe "Gems::VERSION" do
    it "is a String" do
      expect(Gems::VERSION).to be_a(String)
    end

    it "matches Gems::Version.to_s" do
      expect(Gems::VERSION).to eq(Gems::Version.to_s)
    end
  end
end
