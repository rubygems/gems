RSpec.describe Gems::Profile do
  subject(:profile) { described_class.new("id" => 1, "handle" => "qrush", "email" => "nick@quaran.to", "mfa" => "ui_and_api") }

  it "is a Resource" do
    expect(profile).to be_a(Gems::Resource)
  end

  it "is identified by its id and handle" do
    expect(profile.identity).to eq([1, "qrush"])
  end

  it "inspects as the handle" do
    expect(profile.inspect).to eq('#<Gems::Profile handle="qrush">')
  end

  it "exposes the id" do
    expect(profile.id).to eq(1)
  end

  it "exposes the handle" do
    expect(profile.handle).to eq("qrush")
  end

  it "exposes the email" do
    expect(profile.email).to eq("nick@quaran.to")
  end

  it "exposes the mfa level" do
    expect(profile.mfa).to eq("ui_and_api")
  end

  it "exposes the warning" do
    profile = described_class.new("warning" => "For protection of your account and gems, we encourage you to set up MFA.")

    expect(profile.warning).to start_with("For protection of your account")
  end
end
