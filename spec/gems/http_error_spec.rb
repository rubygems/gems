RSpec.describe Gems::HTTPError do
  let(:response) { build_response(Net::HTTPNotFound, "404", "Not Found", "This rubygem could not be found.") }

  it "is an Error" do
    expect(described_class.new(response:)).to be_a(Gems::Error)
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
    Gems::TooManyRedirects => Gems::Error
  }.each do |error_class, parent_class|
    it "defines #{error_class} as a #{parent_class}" do
      expect(error_class.superclass).to eq(parent_class)
    end
  end
end
