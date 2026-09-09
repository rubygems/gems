RSpec.describe Gems::HTTPError do
  let(:response) { build_response(Net::HTTPNotFound, "404", "Not Found", "This rubygem could not be found.") }

  it "is a GemError" do
    expect(described_class.new(response:)).to be_a(Gems::GemError)
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

    it "exposes the response" do
      expect(described_class.new(response:).response).to equal(response)
    end

    it "exposes the status code" do
      expect(described_class.new(response:).code).to eq("404")
    end

    it "accepts a message instead of a response" do
      error = described_class.new("Custom message")

      expect([error.message, error.response, error.code]).to eq(["Custom message", nil, nil])
    end

    it "prefers an explicit message over the response body" do
      expect(described_class.new("Custom message", response:).message).to eq("Custom message")
    end

    it "uses the class name as the message without a message or response" do
      expect(described_class.new.message).to eq("Gems::HTTPError")
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
    Gems::TooManyRedirects => Gems::GemError
  }.each do |error_class, parent_class|
    it "defines #{error_class} as a #{parent_class}" do
      expect(error_class.superclass).to eq(parent_class)
    end
  end
end
