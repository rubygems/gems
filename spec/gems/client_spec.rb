require 'helper'

describe Gems::Client do
  before do
    @client = Gems::Client.new
  end

  describe "#info" do
    before do
      stub_get("/api/v1/gems/rails.json").to_return(:body => fixture("rails.json"))
    end

    it "should return some basic information about the given gem" do
      info = @client.info 'rails'
      a_get("/api/v1/gems/rails.json").should have_been_made
      info.name.should == 'rails'
    end
  end

  describe "#search" do
    before do
      stub_get("/api/v1/gems/search.json?query=cucumber").to_return(:body => fixture("search.json"))
    end

    it "should return an array of active gems that match the query" do
      search = @client.search 'cucumber'
      a_get("/api/v1/gems/search.json?query=cucumber").should have_been_made
      search.first.name.should == 'cucumber'
    end
  end
end
