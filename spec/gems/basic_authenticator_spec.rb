RSpec.describe Gems::BasicAuthenticator do
  subject(:authenticator) { described_class.new(username: "user", password: "pass") }

  it "is an Authenticator" do
    expect(authenticator).to be_a(Gems::Authenticator)
  end

  describe "#initialize" do
    it "sets the username" do
      expect(authenticator.username).to eq("user")
    end

    it "sets the password" do
      expect(authenticator.password).to eq("pass")
    end
  end

  describe "#header" do
    it "returns a basic Authorization header" do
      expect(authenticator.header(Net::HTTP::Get.new("/"))).to eq("Authorization" => "Basic dXNlcjpwYXNz")
    end

    it "encodes long credentials without line breaks" do
      authenticator = described_class.new(username: "u" * 40, password: "p" * 40)

      expect(authenticator.header(nil)["Authorization"]).not_to include("\n")
    end
  end
end
