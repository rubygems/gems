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

      expect([gem.class, gem.name]).to eq([Gems::Gem, "jevalyn"])
    end

    it "raises InvalidResponse when the response is not a list of gems" do
      stub_get("/api/v1/activity/latest.json").to_return(body: '"teapot"')

      expect { client.latest }.to raise_error(an_instance_of(Gems::InvalidResponse).and(having_attributes(body: '"teapot"')))
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

      expect([gem.class, gem.name]).to eq([Gems::Gem, "posthog-ruby"])
    end

    it "raises InvalidResponse when the response is not a list of gems" do
      stub_get("/api/v1/activity/just_updated.json").to_return(body: '"teapot"')

      expect { client.just_updated }.to raise_error(an_instance_of(Gems::InvalidResponse).and(having_attributes(body: '"teapot"')))
    end
  end
end
