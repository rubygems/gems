RSpec.describe Gems::Dependency do
  subject(:dependency) { described_class.new("name" => "thor", "requirements" => ">= 0.14.6") }

  it "is a Resource" do
    expect(dependency).to be_a(Gems::Resource)
  end

  it "is identified by its name and requirements" do
    expect(dependency.identity).to eq(["thor", ">= 0.14.6"])
  end

  it "inspects as the name and requirements" do
    expect(dependency.inspect).to eq('#<Gems::Dependency name="thor" requirements=">= 0.14.6">')
  end

  it "exposes the name" do
    expect(dependency.name).to eq("thor")
  end

  it "exposes the requirements" do
    expect(dependency.requirements).to eq(">= 0.14.6")
  end
end
