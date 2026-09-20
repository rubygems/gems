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

    context "with a block" do
      it "returns what the block returns for the parsed JSON" do
        expect(parser.send(:parse_json, '{"name":"rails"}') { |json| json.fetch("name") }).to eq("rails")
      end

      it "raises InvalidResponse when the block fetches a missing key" do
        expect { parser.send(:parse_json, "{}") { |json| json.fetch("name") } }
          .to raise_error(Gems::InvalidResponse, 'The response body is not the expected JSON: key not found: "name"')
      end

      it "raises InvalidResponse when the block calls a method the JSON lacks" do
        expect { parser.send(:parse_json, '"rails"') { |json| json.fetch("name") } }
          .to raise_error(Gems::InvalidResponse, /\AThe response body is not the expected JSON: undefined method 'fetch'/)
      end

      it "raises InvalidResponse when the block fetches a key from a list" do
        expect { parser.send(:parse_json, "[]") { |json| json.fetch("name") } }
          .to raise_error(Gems::InvalidResponse, /\AThe response body is not the expected JSON: no implicit conversion/)
      end

      it "attaches the body to the error" do
        expect { parser.send(:parse_json, "{}") { |json| json.fetch("name") } }.to raise_error(having_attributes(body: "{}"))
      end

      it "keeps the block's error as the cause" do
        expect { parser.send(:parse_json, "{}") { |json| json.fetch("name") } }
          .to raise_error(having_attributes(cause: an_instance_of(KeyError)))
      end

      it "does not rescue other errors the block raises" do
        expect { parser.send(:parse_json, "{}") { raise ArgumentError, "mine" } }.to raise_error(ArgumentError, "mine")
      end

      it "raises InvalidResponse for a body that is not JSON before calling the block" do
        expect { parser.send(:parse_json, "<html>") { raise "unreached" } }
          .to raise_error(Gems::InvalidResponse, "The response body is not JSON")
      end
    end
  end
end
