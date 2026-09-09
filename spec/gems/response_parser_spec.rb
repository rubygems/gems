RSpec.describe Gems::ResponseParser do
  subject(:parser) { described_class.new }

  let(:uri) { URI("https://rubygems.org/api/v1/gems/rails.json") }

  def response
    Net::HTTP.get_response(uri)
  end

  describe "#parse" do
    it "returns the body of a successful response" do
      stub_request(:get, uri.to_s).to_return(body: "body")

      expect(parser.parse(response:)).to eq("body")
    end

    it "returns an empty string when the body is nil" do
      response = build_response(Net::HTTPNoContent, "204", "No Content", nil)

      expect(parser.parse(response:)).to eq("")
    end

    it "returns the body of other successful responses" do
      stub_request(:get, uri.to_s).to_return(status: 201, body: "created")

      expect(parser.parse(response:)).to eq("created")
    end

    described_class::ERROR_MAP.each do |status, error_class|
      it "raises #{error_class} for a #{status} response" do
        stub_request(:get, uri.to_s).to_return(status:)

        expect { parser.parse(response:) }.to raise_error(error_class)
      end
    end

    it "raises HTTPError for an unmapped error status" do
      stub_request(:get, uri.to_s).to_return(status: 418)

      expect { parser.parse(response:) }.to raise_error(Gems::HTTPError)
    end

    it "does not raise a subclass for an unmapped error status" do
      stub_request(:get, uri.to_s).to_return(status: 418)

      expect { parser.parse(response:) }.to raise_error(an_instance_of(Gems::HTTPError))
    end

    it "raises HTTPError for a redirect response" do
      stub_request(:get, uri.to_s).to_return(status: 302)

      expect { parser.parse(response:) }.to raise_error(Gems::HTTPError)
    end

    it "uses the response body as the error message" do
      stub_request(:get, uri.to_s).to_return(status: 404, body: "This rubygem could not be found.")

      expect { parser.parse(response:) }.to raise_error(Gems::NotFound, "This rubygem could not be found.")
    end

    it "attaches the response to the error" do
      stub_request(:get, uri.to_s).to_return(status: 500)

      expect { parser.parse(response:) }.to(raise_error { |error| expect(error.code).to eq("500") })
    end
  end
end
