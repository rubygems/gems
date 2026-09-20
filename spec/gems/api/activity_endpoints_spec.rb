# frozen_string_literal: true

RSpec.describe Gems::API::ActivityEndpoints do
  let(:client) { Gems::Client.new(key: nil, username: nil, password: nil) }

  describe "#latest" do
    before { stub_get("/api/v1/activity/latest.json").to_return(body: fixture("latest.json")) }

    it "gets the correct resource" do
      client.latest

      expect(a_get("/api/v1/activity/latest.json")).to have_been_made
    end

    it "returns the latest gems" do
      gem = client.latest.first

      expect([gem.class, gem.name]).to eq([Gems::Gem, "seanwalbran-rpm_contrib"])
    end

    it "passes options as query parameters" do
      stub_get("/api/v1/activity/latest.json?page=2").to_return(body: fixture("latest.json"))
      client.latest(page: 2)

      expect(a_get("/api/v1/activity/latest.json?page=2")).to have_been_made
    end
  end

  describe "#latest_each" do
    before do
      stub_get("/api/v1/activity/latest.json?page=1").to_return(body: fixture("latest.json"))
      stub_get("/api/v1/activity/latest.json?page=2").to_return(body: "[]")
    end

    it "returns an enumerator" do
      expect(client.latest_each).to be_a(Enumerator)
    end

    it "enumerates the gems of every page until one is empty" do
      client.latest_each.to_a

      expect(a_get("/api/v1/activity/latest.json?page=2")).to have_been_made
    end

    it "returns the gems" do
      gem = client.latest_each.first

      expect([gem.class, gem.name]).to eq([Gems::Gem, "seanwalbran-rpm_contrib"])
    end

    it "does not request a page the enumeration does not reach" do
      client.latest_each.first

      expect(a_get("/api/v1/activity/latest.json?page=2")).not_to have_been_made
    end

    it "calls a block with each gem" do
      names = []
      client.latest_each { |gem| names << gem.name }

      expect(names.first).to eq("seanwalbran-rpm_contrib")
    end
  end

  describe "#just_updated" do
    before { stub_get("/api/v1/activity/just_updated.json").to_return(body: fixture("just_updated.json")) }

    it "gets the correct resource" do
      client.just_updated

      expect(a_get("/api/v1/activity/just_updated.json")).to have_been_made
    end

    it "returns the most recently updated gems" do
      gem = client.just_updated.first

      expect([gem.class, gem.name]).to eq([Gems::Gem, "rspec-tag_matchers"])
    end

    it "passes options as query parameters" do
      stub_get("/api/v1/activity/just_updated.json?page=2").to_return(body: fixture("just_updated.json"))
      client.just_updated(page: 2)

      expect(a_get("/api/v1/activity/just_updated.json?page=2")).to have_been_made
    end
  end

  describe "#just_updated_each" do
    before do
      stub_get("/api/v1/activity/just_updated.json?page=1").to_return(body: fixture("just_updated.json"))
      stub_get("/api/v1/activity/just_updated.json?page=2").to_return(body: "[]")
    end

    it "returns an enumerator" do
      expect(client.just_updated_each).to be_a(Enumerator)
    end

    it "enumerates the gems of every page until one is empty" do
      client.just_updated_each.to_a

      expect(a_get("/api/v1/activity/just_updated.json?page=2")).to have_been_made
    end

    it "returns the gems" do
      gem = client.just_updated_each.first

      expect([gem.class, gem.name]).to eq([Gems::Gem, "rspec-tag_matchers"])
    end

    it "calls a block with each gem" do
      names = []
      client.just_updated_each { |gem| names << gem.name }

      expect(names.first).to eq("rspec-tag_matchers")
    end
  end
end
