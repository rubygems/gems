RSpec.describe Gems::OtpAuthenticator do
  subject(:authenticator) { described_class.new(authenticator: api_key_authenticator, otp: "123456") }

  let(:api_key_authenticator) { Gems::ApiKeyAuthenticator.new(key: TEST_KEY) }
  let(:request) { Net::HTTP::Get.new("/") }

  it "is an Authenticator" do
    expect(authenticator).to be_a(Gems::Authenticator)
  end

  describe "#initialize" do
    it "sets the wrapped authenticator" do
      expect(authenticator.authenticator).to equal(api_key_authenticator)
    end

    it "sets the one-time passcode" do
      expect(authenticator.otp).to eq("123456")
    end
  end

  describe "#header" do
    it "adds the OTP header to the wrapped authenticator's headers" do
      expect(authenticator.header(request)).to eq("Authorization" => TEST_KEY, "OTP" => "123456")
    end

    it "passes the request to the wrapped authenticator" do
      wrapped = instance_double(Gems::Authenticator)
      allow(wrapped).to receive(:header).and_return({})
      described_class.new(authenticator: wrapped, otp: "123456").header(request)

      expect(wrapped).to have_received(:header).with(request)
    end

    it "adds only the OTP header when the wrapped authenticator has none" do
      authenticator = described_class.new(authenticator: Gems::Authenticator.new, otp: "123456")

      expect(authenticator.header(request)).to eq("OTP" => "123456")
    end
  end

  describe "#inspect" do
    it "shows the wrapped authenticator without the passcode" do
      expect(authenticator.inspect).to eq("#<Gems::OtpAuthenticator authenticator=#<Gems::ApiKeyAuthenticator>>")
    end
  end
end
