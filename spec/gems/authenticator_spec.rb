RSpec.describe Gems::Authenticator do
  subject(:authenticator) { described_class.new }

  describe "#header" do
    it "returns no headers" do
      expect(authenticator.header(Net::HTTP::Get.new("/"))).to eq({})
    end
  end
end
