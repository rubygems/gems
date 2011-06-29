require 'helper'

describe Gems::Client do
  %w(json xml).each do |format|
    context ".new(:format => '#{format}')" do
      before do
        Gems.configure do |config|
          config.format   = format
          config.key      = '701243f217cdf23b1370c7b66b65ca97'
          config.username = 'nick@gemcutter.org'
          config.password = 'schwwwwing'
        end
      end

      after do
        Gems.reset
      end

      describe ".info" do
        before do
          stub_get("/api/v1/gems/rails.#{format}").
            to_return(:body => fixture("rails.#{format}"))
        end

        it "should return some basic information about the given gem" do
          info = Gems.info 'rails'
          a_get("/api/v1/gems/rails.#{format}").
            should have_been_made
          info.name.should == 'rails'
        end
      end

      describe ".search" do
        before do
          stub_get("/api/v1/search.#{format}").
            with(:query => {"query" => "cucumber"}).
            to_return(:body => fixture("search.#{format}"))
        end

        it "should return an array of active gems that match the query" do
          search = Gems.search 'cucumber'
          a_get("/api/v1/search.#{format}").
            with(:query => {"query" => "cucumber"}).
            should have_been_made
          search.first.name.should == 'cucumber'
        end
      end

      describe ".versions" do
        before do
          stub_get("/api/v1/versions/coulda.json").
            to_return(:body => fixture("coulda.json"))
        end

        it "should return an array of gem version details" do
          versions = Gems.versions 'coulda'
          a_get("/api/v1/versions/coulda.json").
            should have_been_made
          versions.first.number.should == '0.6.3'
        end
      end

      describe ".downloads" do
        before do
          stub_get("/api/v1/versions/coulda-0.6.3/downloads.json").
            to_return(:body => fixture("downloads.json"))
        end

        it "should return the number of downloads by day for a particular gem version" do
          downloads = Gems.downloads 'coulda', '0.6.3'
          a_get("/api/v1/versions/coulda-0.6.3/downloads.json").
            should have_been_made
          downloads["2011-06-22"].should == 8
        end
      end

      describe ".dependencies" do
        before do
          stub_get("/api/v1/dependencies").
            with(:query => {"gems" => "rails,thor"}).
            to_return(:body => fixture("dependencies"))
        end

        it "should return an array of hashes for all versions of given gems" do
          dependencies = Gems.dependencies 'rails', 'thor'
          a_get("/api/v1/dependencies").
            with(:query => {"gems" => "rails,thor"}).
            should have_been_made
          dependencies.first.number.should == "3.0.9"
        end
      end

      describe ".api_key" do
        before do
          stub_get("/api/v1/api_key").
            to_return(:body => fixture("api_key"))
        end

        it "should retrieve an API key" do
          api_key = Gems.api_key
          a_get("/api/v1/api_key").
            should have_been_made
          api_key.should == "701243f217cdf23b1370c7b66b65ca97"
        end
      end

      describe ".gems" do
        before do
          stub_get("/api/v1/gems.#{format}").
            to_return(:body => fixture("gems.#{format}"))
        end

        it "should list all gems that you own" do
          gems = Gems.gems
          a_get("/api/v1/gems.#{format}").
            should have_been_made
          gems.first.name.should == "congress"
        end
      end

      describe ".owners" do
        before do
          stub_get("/api/v1/gems/gems/owners.json").
            to_return(:body => fixture("owners.json"))
        end

        it "should list all owners of a gem" do
          owners = Gems.owners("gems")
          a_get("/api/v1/gems/gems/owners.json").
            should have_been_made
          owners.first.email.should == "sferik@gmail.com"
        end
      end
    end
  end
end
