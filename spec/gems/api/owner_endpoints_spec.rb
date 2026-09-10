RSpec.describe Gems::API::OwnerEndpoints do
  let(:client) { Gems::Client.new(key: nil, username: nil, password: nil) }

  describe "#owners" do
    before { stub_get("/api/v1/gems/gems/owners.json").to_return(body: fixture("owners.json")) }

    it "accepts a gem" do
      stub_get("/api/v1/gems/gems/owners.json").to_return(body: fixture("owners.json"))
      client.owners(Gems::Gem.new("name" => "gems"))

      expect(a_get("/api/v1/gems/gems/owners.json")).to have_been_made
    end

    it "gets the correct resource" do
      client.owners("gems")

      expect(a_get("/api/v1/gems/gems/owners.json")).to have_been_made
    end

    it "returns the gem's owners" do
      owner = client.owners("gems").first

      expect([owner.class, owner.email]).to eq([Gems::Owner, "sferik@gmail.com"])
    end
  end

  describe "#add_owner" do
    before { stub_post("/api/v1/gems/gems/owners").to_return(body: fixture("add_owner")) }

    it "accepts a gem and an owner, using the owner's handle" do
      stub_post("/api/v1/gems/gems/owners").to_return(body: fixture("add_owner"))
      client.add_owner(Gems::Gem.new("name" => "gems"), Gems::Owner.new("handle" => "sferik", "email" => "sferik@gmail.com"))

      expect(a_post("/api/v1/gems/gems/owners").with(body: {email: "sferik"})).to have_been_made
    end

    it "posts the correct resource" do
      client.add_owner("gems", "sferik@gmail.com")

      expect(a_post("/api/v1/gems/gems/owners").with(body: {email: "sferik@gmail.com"})).to have_been_made
    end

    it "posts a role" do
      client.add_owner("gems", "sferik@gmail.com", role: "maintainer")

      expect(a_post("/api/v1/gems/gems/owners").with(body: {email: "sferik@gmail.com", role: "maintainer"})).to have_been_made
    end

    it "returns the response body" do
      expect(client.add_owner("gems", "sferik@gmail.com")).to eq("Owner added successfully.")
    end
  end

  describe "#update_owner" do
    before { stub_request(:patch, rubygems_url("/api/v1/gems/gems/owners")).to_return(body: fixture("update_owner")) }

    it "accepts a gem and an owner, using the owner's handle" do
      client.update_owner(Gems::Gem.new("name" => "gems"), Gems::Owner.new("handle" => "sferik"), role: "maintainer")

      expect(a_request(:patch, rubygems_url("/api/v1/gems/gems/owners"))
        .with(body: {email: "sferik", role: "maintainer"})).to have_been_made
    end

    it "patches the correct resource" do
      client.update_owner("gems", "sferik@gmail.com", role: "maintainer")

      expect(a_request(:patch, rubygems_url("/api/v1/gems/gems/owners"))
        .with(body: {email: "sferik@gmail.com", role: "maintainer"})).to have_been_made
    end

    it "returns the response body" do
      expect(client.update_owner("gems", "sferik@gmail.com", role: "maintainer")).to eq("Owner updated successfully.")
    end
  end

  describe "#remove_owner" do
    before { stub_delete("/api/v1/gems/gems/owners?email=sferik@gmail.com").to_return(body: fixture("remove_owner")) }

    it "accepts a gem and an owner, using the owner's email without a handle" do
      stub_delete("/api/v1/gems/gems/owners?email=sferik@gmail.com").to_return(body: fixture("remove_owner"))
      client.remove_owner(Gems::Gem.new("name" => "gems"), Gems::Owner.new("email" => "sferik@gmail.com"))

      expect(a_delete("/api/v1/gems/gems/owners?email=sferik@gmail.com")).to have_been_made
    end

    it "deletes the correct resource" do
      client.remove_owner("gems", "sferik@gmail.com")

      expect(a_delete("/api/v1/gems/gems/owners?email=sferik@gmail.com")).to have_been_made
    end

    it "returns the response body" do
      expect(client.remove_owner("gems", "sferik@gmail.com")).to eq("Owner removed successfully.")
    end
  end
end
