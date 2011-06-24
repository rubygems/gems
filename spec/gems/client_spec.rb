require 'helper'

describe Gems::Client do
  %w(json xml).each do |format|
    context ".new(:format => '#{format}')" do
      before do
        @client = Gems::Client.new(:format => format)
      end

      describe ".info" do
        before do
          stub_get("/api/v1/gems/rails.#{format}").
            to_return(:body => fixture("rails.#{format}"))
        end

        it "should return some basic information about the given gem" do
          info = @client.info 'rails'
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
          search = @client.search 'cucumber'
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
          versions = @client.versions 'coulda'
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
          downloads = @client.downloads 'coulda', '0.6.3'
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
          dependencies = @client.dependencies 'rails', 'thor'
          a_get("/api/v1/dependencies").
            with(:query => {"gems" => "rails,thor"}).
            should have_been_made
          dependencies.first.number.should == "3.0.9"
        end
      end
    end
  end
end
