RSpec.describe Gems::PathEscaping do
  subject(:escaper) { Class.new { include Gems::PathEscaping }.new }

  describe "#escape" do
    {
      "rails" => "rails",
      "rails-api" => "rails-api",
      "net_http" => "net_http",
      "7.0.6" => "7.0.6",
      "nokogiri-1.15.0-x86_64-linux" => "nokogiri-1.15.0-x86_64-linux",
      "~tilde" => "~tilde",
      "../../api/v1/profile/me" => "..%2F..%2Fapi%2Fv1%2Fprofile%2Fme",
      "rails?platform=java" => "rails%3Fplatform%3Djava",
      "rails#fragment" => "rails%23fragment",
      "foo bar" => "foo%20bar",
      "r\u00e4ils" => "r%C3%A4ils",
      "josh@technicalpickles.com" => "josh%40technicalpickles.com",
      "%" => "%25"
    }.each do |value, escaped|
      it "escapes #{value.inspect} as #{escaped.inspect}" do
        expect(escaper.send(:escape, value)).to eq(escaped)
      end
    end

    it "reads a value that is not a String as a String" do
      expect(escaper.send(:escape, 12_345)).to eq("12345")
    end

    it "returns an empty string for nil" do
      expect(escaper.send(:escape, nil)).to eq("")
    end
  end
end
