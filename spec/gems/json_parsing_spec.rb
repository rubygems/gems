RSpec.describe Gems::JSONParsing do
  subject(:parser) { Class.new { include Gems::JSONParsing }.new }

  describe "#parse_json" do
    it "parses a JSON body" do
      expect(parser.send(:parse_json, '{"name":"rails"}')).to eq("name" => "rails")
    end

    it "raises InvalidResponse for a body that is not JSON" do
      expect { parser.send(:parse_json, "<html>") }.to raise_error(Gems::InvalidResponse, "The response body is not JSON")
    end

    it "attaches the body to the error" do
      expect { parser.send(:parse_json, "<html>") }.to raise_error(having_attributes(body: "<html>"))
    end

    it "keeps the parser error as the cause" do
      expect { parser.send(:parse_json, "<html>") }.to raise_error(having_attributes(cause: an_instance_of(JSON::ParserError)))
    end

    it "raises InvalidResponse for an empty body" do
      expect { parser.send(:parse_json, "") }.to raise_error(Gems::InvalidResponse)
    end
  end
end
