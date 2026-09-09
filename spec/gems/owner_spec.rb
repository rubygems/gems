RSpec.describe Gems::Owner do
  subject(:owner) { described_class.new("id" => 1, "handle" => "sferik", "email" => "sferik@gmail.com", "role" => "owner") }

  it "is a Resource" do
    expect(owner).to be_a(Gems::Resource)
  end

  it "is identified by its id, handle, and email" do
    expect(owner.identity).to eq([1, "sferik", "sferik@gmail.com"])
  end

  it "inspects as the handle" do
    expect(owner.inspect).to eq('#<Gems::Owner handle="sferik">')
  end

  it "exposes the id" do
    expect(owner.id).to eq(1)
  end

  it "exposes the handle" do
    expect(owner.handle).to eq("sferik")
  end

  it "exposes the email" do
    expect(owner.email).to eq("sferik@gmail.com")
  end

  it "exposes the role" do
    expect(owner.role).to eq("owner")
  end
end
