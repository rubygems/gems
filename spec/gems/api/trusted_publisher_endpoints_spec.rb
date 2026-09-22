# frozen_string_literal: true

RSpec.describe Gems::API::TrustedPublisherEndpoints do
  let(:client) { Gems::Client.new(key: TEST_KEY) }

  describe "#trusted_publishers" do
    before { stub_get("/api/v1/gems/gems/trusted_publishers").to_return(body: fixture("trusted_publishers.json")) }

    it "gets the correct resource" do
      client.trusted_publishers("gems")

      expect(a_get("/api/v1/gems/gems/trusted_publishers")).to have_been_made
    end

    it "accepts a gem" do
      client.trusted_publishers(Gems::Gem.new("name" => "gems"))

      expect(a_get("/api/v1/gems/gems/trusted_publishers")).to have_been_made
    end

    it "escapes the gem name" do
      stub_get("/api/v1/gems/..%2Fgems/trusted_publishers").to_return(body: fixture("trusted_publishers.json"))
      client.trusted_publishers("../gems")

      expect(a_get("/api/v1/gems/..%2Fgems/trusted_publishers")).to have_been_made
    end

    it "returns the gem's trusted publishers" do
      trusted_publisher = client.trusted_publishers("gems").first

      expect([trusted_publisher.class, trusted_publisher.id]).to eq([Gems::TrustedPublisher, 1])
    end

    it "returns every trusted publisher" do
      expect(client.trusted_publishers("gems").map(&:workflow_filename)).to eq(%w[push_gem.yml release.yml])
    end
  end

  describe "#trusted_publisher" do
    before { stub_get("/api/v1/gems/gems/trusted_publishers/1").to_return(body: fixture("trusted_publisher.json")) }

    it "gets the correct resource" do
      client.trusted_publisher("gems", 1)

      expect(a_get("/api/v1/gems/gems/trusted_publishers/1")).to have_been_made
    end

    it "accepts a trusted publisher, using its ID" do
      client.trusted_publisher("gems", Gems::TrustedPublisher.new("id" => 1))

      expect(a_get("/api/v1/gems/gems/trusted_publishers/1")).to have_been_made
    end

    it "escapes the gem name and the ID" do
      stub_get("/api/v1/gems/..%2Fgems/trusted_publishers/..%2F1").to_return(body: fixture("trusted_publisher.json"))
      client.trusted_publisher("../gems", "../1")

      expect(a_get("/api/v1/gems/..%2Fgems/trusted_publishers/..%2F1")).to have_been_made
    end

    it "returns the trusted publisher" do
      trusted_publisher = client.trusted_publisher("gems", 1)

      expect([trusted_publisher.class, trusted_publisher.workflow_filename]).to eq([Gems::TrustedPublisher, "push_gem.yml"])
    end
  end

  describe "#add_trusted_publisher" do
    before do
      stub_post("/api/v1/gems/gems/trusted_publishers").to_return(body: fixture("trusted_publisher.json"), status: 201)
    end

    let(:publisher) { {repository_owner: "rubygems", repository_name: "gems", workflow_filename: "push_gem.yml"} }

    it "posts the correct resource" do
      client.add_trusted_publisher("gems", **publisher)

      expect(a_post("/api/v1/gems/gems/trusted_publishers")).to have_been_made
    end

    it "posts the publisher as JSON" do
      client.add_trusted_publisher("gems", **publisher)
      body = {trusted_publisher_type: Gems::TrustedPublisher::GITHUB_ACTION, trusted_publisher: publisher}

      expect(a_post("/api/v1/gems/gems/trusted_publishers")
        .with(body: JSON.generate(body), headers: {"Content-Type" => "application/json"})).to have_been_made
    end

    it "accepts a gem" do
      client.add_trusted_publisher(Gems::Gem.new("name" => "gems"), **publisher)

      expect(a_post("/api/v1/gems/gems/trusted_publishers")).to have_been_made
    end

    it "escapes the gem name" do
      stub_post("/api/v1/gems/..%2Fgems/trusted_publishers").to_return(body: fixture("trusted_publisher.json"))
      client.add_trusted_publisher("../gems", **publisher)

      expect(a_post("/api/v1/gems/..%2Fgems/trusted_publishers")).to have_been_made
    end

    it "posts an environment" do
      client.add_trusted_publisher("gems", **publisher, environment: "production")

      expect(a_post("/api/v1/gems/gems/trusted_publishers")
        .with(body: /"environment":"production"/)).to have_been_made
    end

    it "posts the repository of a reusable workflow" do
      client.add_trusted_publisher("gems", **publisher, workflow_repository_owner: "rubygems",
        workflow_repository_name: "workflows")

      expect(a_post("/api/v1/gems/gems/trusted_publishers")
        .with(body: /"workflow_repository_owner":"rubygems","workflow_repository_name":"workflows"/)).to have_been_made
    end

    it "leaves out the fields it was not given" do
      client.add_trusted_publisher("gems", **publisher)

      expect(a_post("/api/v1/gems/gems/trusted_publishers").with { |request| !request.body.include?("environment") })
        .to have_been_made
    end

    it "posts another type" do
      client.add_trusted_publisher("gems", **publisher, type: "OIDC::TrustedPublisher::GitLabCI")

      expect(a_post("/api/v1/gems/gems/trusted_publishers")
        .with(body: /"trusted_publisher_type":"OIDC::TrustedPublisher::GitLabCI"/)).to have_been_made
    end

    it "returns the trusted publisher that was added" do
      trusted_publisher = client.add_trusted_publisher("gems", **publisher)

      expect([trusted_publisher.class, trusted_publisher.id]).to eq([Gems::TrustedPublisher, 1])
    end

    it "raises UnprocessableEntity when the publisher is refused" do
      stub_post("/api/v1/gems/gems/trusted_publishers")
        .to_return(status: 422, body: '{"errors":{"base":["publisher already exists"]}}')

      expect { client.add_trusted_publisher("gems", **publisher) }.to raise_error(Gems::UnprocessableEntity)
    end
  end

  describe "#remove_trusted_publisher" do
    before { stub_delete("/api/v1/gems/gems/trusted_publishers/1").to_return(body: "", status: 204) }

    it "deletes the correct resource" do
      client.remove_trusted_publisher("gems", 1)

      expect(a_delete("/api/v1/gems/gems/trusted_publishers/1")).to have_been_made
    end

    it "accepts a gem and a trusted publisher, using its ID" do
      client.remove_trusted_publisher(Gems::Gem.new("name" => "gems"), Gems::TrustedPublisher.new("id" => 1))

      expect(a_delete("/api/v1/gems/gems/trusted_publishers/1")).to have_been_made
    end

    it "escapes the gem name and the ID" do
      stub_delete("/api/v1/gems/..%2Fgems/trusted_publishers/..%2F1").to_return(body: "")
      client.remove_trusted_publisher("../gems", "../1")

      expect(a_delete("/api/v1/gems/..%2Fgems/trusted_publishers/..%2F1")).to have_been_made
    end

    it "returns a message saying the trusted publisher was removed, since the endpoint answers with none" do
      expect(client.remove_trusted_publisher("gems", 1)).to eq("Trusted publisher removed successfully.")
    end

    it "returns the message the endpoint answers with, when it answers with one" do
      stub_delete("/api/v1/gems/gems/trusted_publishers/1").to_return(body: "Removed.")

      expect(client.remove_trusted_publisher("gems", 1)).to eq("Removed.")
    end
  end
end
