RSpec.describe Gems::HTTPError do
  let(:response) { build_response(Net::HTTPNotFound, "404", "Not Found", "This rubygem could not be found.") }

  it "is an Error" do
    expect(described_class.new(response:)).to be_a(Gems::Error)
  end

  it "is rescuable as the deprecated GemError" do
    expect { raise described_class.new(response:) }.to raise_error(Gems.const_get(:GemError, false))
  end

  describe "#initialize" do
    it "uses the response body as the message" do
      expect(described_class.new(response:).message).to eq("This rubygem could not be found.")
    end

    it "falls back to the status message when the body is empty" do
      response = build_response(Net::HTTPNotFound, "404", "Not Found", "")

      expect(described_class.new(response:).message).to eq("Not Found")
    end

    it "falls back to the status message when the body is nil" do
      response = build_response(Net::HTTPNotFound, "404", "Not Found", nil)

      expect(described_class.new(response:).message).to eq("Not Found")
    end

    it "falls back to the status message when the body is an HTML page" do
      response = build_response(Net::HTTPBadGateway, "502", "Bad Gateway", "<html><body>Bad Gateway</body></html>")
      response["Content-Type"] = "Text/HTML; charset=utf-8"

      expect(described_class.new(response:).message).to eq("Bad Gateway")
    end

    it "uses the body of a text response as the message" do
      response["Content-Type"] = "text/plain; charset=utf-8"

      expect(described_class.new(response:).message).to eq("This rubygem could not be found.")
    end

    it "exposes the response" do
      expect(described_class.new(response:).response).to equal(response)
    end

    it "exposes the status code" do
      expect(described_class.new(response:).code).to eq(404)
    end
  end

  describe "#retry_after" do
    let(:response) { build_response(Net::HTTPTooManyRequests, "429", "Too Many Requests", "") }
    let(:date) { "Wed, 21 Oct 2015 07:28:00 GMT" }

    it "is nil without a Retry-After header" do
      expect(described_class.new(response:).retry_after).to be_nil
    end

    it "returns the seconds of a Retry-After header" do
      response["Retry-After"] = "120"

      expect(described_class.new(response:).retry_after).to eq(120)
    end

    it "returns the seconds until the HTTP date of a Retry-After header, rounded up" do
      response["Retry-After"] = date
      allow(Time).to receive(:now).and_return(Time.httpdate(date) - 1.2)

      expect(described_class.new(response:).retry_after).to eq(2)
    end

    it "returns zero for an HTTP date that has passed" do
      response["Retry-After"] = date

      expect(described_class.new(response:).retry_after).to eq(0)
    end

    it "is nil for a Retry-After header that is neither seconds nor an HTTP date" do
      response["Retry-After"] = "soon"

      expect(described_class.new(response:).retry_after).to be_nil
    end
  end

  {
    Gems::ClientError => described_class,
    Gems::ServerError => described_class,
    Gems::BadRequest => Gems::ClientError,
    Gems::Unauthorized => Gems::ClientError,
    Gems::Forbidden => Gems::ClientError,
    Gems::NotFound => Gems::ClientError,
    Gems::Conflict => Gems::ClientError,
    Gems::UnprocessableEntity => Gems::ClientError,
    Gems::TooManyRequests => Gems::ClientError,
    Gems::InternalServerError => Gems::ServerError,
    Gems::BadGateway => Gems::ServerError,
    Gems::ServiceUnavailable => Gems::ServerError,
    Gems::GatewayTimeout => Gems::ServerError,
    Gems::NetworkError => Gems::Error,
    Gems::TooManyRedirects => Gems::Error
  }.each do |error_class, parent_class|
    it "defines #{error_class} as a #{parent_class}" do
      expect(error_class.superclass).to eq(parent_class)
    end
  end
end
