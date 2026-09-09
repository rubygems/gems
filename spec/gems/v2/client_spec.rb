RSpec.describe Gems::V2::Client do
  subject(:client) { described_class.new(key: nil, username: nil, password: nil) }

  it "is a Gems::BaseClient" do
    expect(client).to be_a(Gems::BaseClient)
  end

  describe "#info" do
    context "when the gem version exists" do
      before { stub_get("/api/v2/rubygems/rails/versions/7.0.6.json").to_return(body: fixture("v2/rails-7.0.6.json")) }

      it "gets the correct resource" do
        client.info("rails", "7.0.6")

        expect(a_get("/api/v2/rubygems/rails/versions/7.0.6.json")).to have_been_made
      end

      it "returns information about the gem version" do
        expect(client.info("rails", "7.0.6").values_at("name", "version")).to eq(%w[rails 7.0.6])
      end
    end

    context "when the response is not JSON" do
      before { stub_get("/api/v2/rubygems/rails/versions/7.0.99.json").to_return(body: "This version could not be found.") }

      it "returns an empty hash" do
        expect(client.info("rails", "7.0.99")).to eq({})
      end
    end
  end
end
