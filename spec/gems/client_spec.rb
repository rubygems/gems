require 'helper'

describe Gems::Client do
  before do
    Gems.reset
  end

  describe ".info" do
    before do
      stub_get("/api/v1/gems/rails.yaml").
        to_return(:body => fixture("rails.yaml"))
    end

    it "should return some basic information about the given gem" do
      info = Gems.info 'rails'
      a_get("/api/v1/gems/rails.yaml").
        should have_been_made
      info['name'].should == 'rails'
    end
  end

  describe ".search" do
    before do
      stub_get("/api/v1/search.yaml").
        with(:query => {"query" => "cucumber"}).
        to_return(:body => fixture("search.yaml"))
    end

    it "should return an array of active gems that match the query" do
      search = Gems.search 'cucumber'
      a_get("/api/v1/search.yaml").
        with(:query => {"query" => "cucumber"}).
        should have_been_made
      search.first['name'].should == 'cucumber'
    end
  end

  describe ".versions" do
    before do
      stub_get("/api/v1/versions/script_helpers.yaml").
        to_return(:body => fixture("script_helpers.yaml"))
    end

    it "should return an array of gem version details" do
      versions = Gems.versions 'script_helpers'
      a_get("/api/v1/versions/script_helpers.yaml").
        should have_been_made
      versions.first['number'].should == '0.1.0'
    end
  end

  describe ".total_downloads" do
    context "with no version or gem name specified" do
      before do
        stub_get("/api/v1/downloads.yaml").
          to_return(:body => fixture("total_downloads.yaml"))
      end

      it "should return the total number of downloads on RubyGems.org" do
        downloads = Gems.total_downloads
        a_get("/api/v1/downloads.yaml").
          should have_been_made
        downloads[:total].should == 244368950
      end
    end

    context "with no version specified" do
      before do
        stub_get("/api/v1/gems/rails_admin.yaml").
          to_return(:body => fixture("rails.yaml"))
        stub_get("/api/v1/downloads/rails_admin-3.0.9.yaml").
          to_return(:body => fixture("rails_admin-0.0.0.yaml"))
      end

      it "should the total number of downloads for the specified gem" do
        downloads = Gems.total_downloads('rails_admin')
        a_get("/api/v1/gems/rails_admin.yaml").
          should have_been_made
        a_get("/api/v1/downloads/rails_admin-3.0.9.yaml").
          should have_been_made
        downloads[:version_downloads].should == 3142
        downloads[:total_downloads].should == 3142
      end
    end

    context "with a version specified" do
      before do
        stub_get("/api/v1/downloads/rails_admin-0.0.0.yaml").
          to_return(:body => fixture("rails_admin-0.0.0.yaml"))
      end

      it "should the total number of downloads for the specified gem" do
        downloads = Gems.total_downloads('rails_admin', '0.0.0')
        a_get("/api/v1/downloads/rails_admin-0.0.0.yaml").
          should have_been_made
        downloads[:version_downloads].should == 3142
        downloads[:total_downloads].should == 3142
      end
    end

  end

  describe ".most_downloaded" do
    context "with nothing specified" do
      before do
        stub_get("/api/v1/downloads/all.yaml").
	  to_return(:body => fixture("most_downloaded.yaml"))
      end

      it "should return the most downloaded versions" do
        most_downloaded = Gems.most_downloaded
        a_get("/api/v1/downloads/all.yaml").
          should have_been_made
        most_downloaded[:gems].first.first['full_name'].should == "abstract-1.0.0"
        most_downloaded[:gems].first[1].should == 1
      end
    end
  end

  describe ".downloads" do

    context "with no dates or version specified" do
      before do
        stub_get("/api/v1/gems/coulda.yaml").
          to_return(:body => fixture("rails.yaml"))
        stub_get("/api/v1/versions/coulda-3.0.9/downloads.yaml").
          to_return(:body => fixture("downloads.yaml"))
      end

      it "should return the number of downloads by day for a particular gem version" do
        downloads = Gems.downloads 'coulda'
        a_get("/api/v1/gems/coulda.yaml").
          should have_been_made
        a_get("/api/v1/versions/coulda-3.0.9/downloads.yaml").
          should have_been_made
        downloads['2011-06-22'].should == 8
      end
    end

    context "with no dates specified" do
      before do
        stub_get("/api/v1/versions/coulda-0.6.3/downloads.yaml").
          to_return(:body => fixture("downloads.yaml"))
      end

      it "should return the number of downloads by day for a particular gem version" do
        downloads = Gems.downloads 'coulda', '0.6.3'
        a_get("/api/v1/versions/coulda-0.6.3/downloads.yaml").
          should have_been_made
        downloads['2011-06-22'].should == 8
      end
    end

    context "with from date specified" do
      before do
        stub_get("/api/v1/versions/coulda-0.6.3/downloads/search.yaml").
          with(:query => {"from" => "2011-01-01", "to" => Date.today.to_s}).
          to_return(:body => fixture("downloads.yaml"))
      end

      it "should return the number of downloads by day for a particular gem version" do
        downloads = Gems.downloads 'coulda', '0.6.3', Date.parse('2011-01-01')
        a_get("/api/v1/versions/coulda-0.6.3/downloads/search.yaml").
          with(:query => {"from" => "2011-01-01", "to" => Date.today.to_s}).
          should have_been_made
        downloads['2011-06-22'].should == 8
      end
    end

    context "with from and to dates specified" do
      before do
        stub_get("/api/v1/versions/coulda-0.6.3/downloads/search.yaml").
          with(:query => {"from" => "2011-01-01", "to" => "2011-06-28"}).
          to_return(:body => fixture("downloads.yaml"))
      end

      it "should return the number of downloads by day for a particular gem version" do
        downloads = Gems.downloads 'coulda', '0.6.3', Date.parse('2011-01-01'), Date.parse('2011-06-28')
        a_get("/api/v1/versions/coulda-0.6.3/downloads/search.yaml").
          with(:query => {"from" => "2011-01-01", "to" => "2011-06-28"}).
          should have_been_made
        downloads['2011-06-22'].should == 8
      end
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
      dependencies.first[:number].should == "3.0.9"
    end
  end

  describe ".api_key" do
    before do
      Gems.configure do |config|
        config.username = 'nick@gemcutter.org'
        config.password = 'schwwwwing'
      end
      stub_get("https://nick%40gemcutter.org:schwwwwing@rubygems.org/api/v1/api_key").
        to_return(:body => fixture("api_key"))
    end

    it "should retrieve an API key" do
      api_key = Gems.api_key
      a_get("https://nick%40gemcutter.org:schwwwwing@rubygems.org/api/v1/api_key").
        should have_been_made
      api_key.should == "701243f217cdf23b1370c7b66b65ca97"
    end
  end

  describe ".gems" do
    before do
      stub_get("/api/v1/gems.yaml").
        to_return(:body => fixture("gems.yaml"))
    end

    it "should list all gems that you own" do
      gems = Gems.gems
      a_get("/api/v1/gems.yaml").
        should have_been_made
      gems.first['name'].should == "exchb"
    end
  end

  describe ".owners" do
    before do
      stub_get("/api/v1/gems/gems/owners.yaml").
        to_return(:body => fixture("owners.yaml"))
    end

    it "should list all owners of a gem" do
      owners = Gems.owners("gems")
      a_get("/api/v1/gems/gems/owners.yaml").
        should have_been_made
      owners.first['email'].should == "sferik@gmail.com"
    end
  end

  describe ".add_owner" do
    before do
      stub_post("/api/v1/gems/gems/owners").
        with(:body => {:email => "sferik@gmail.com"}).
        to_return(:body => fixture("add_owner"))
    end

    it "should add an owner to a RubyGem" do
      owner = Gems.add_owner("gems", "sferik@gmail.com")
      a_post("/api/v1/gems/gems/owners").
        with(:body => {:email => "sferik@gmail.com"}).
        should have_been_made
      owner.should == "Owner added successfully."
    end
  end

  describe ".remove_owner" do
    before do
      stub_delete("/api/v1/gems/gems/owners").
        with(:query => {:email => "sferik@gmail.com"}).
        to_return(:body => fixture("remove_owner"))
    end

    it "should remove an owner from a RubyGem" do
      owner = Gems.remove_owner("gems", "sferik@gmail.com")
      a_delete("/api/v1/gems/gems/owners").
        with(:query => {:email => "sferik@gmail.com"}).
        should have_been_made
      owner.should == "Owner removed successfully."
    end
  end

  describe ".web_hooks" do
    before do
      stub_get("/api/v1/web_hooks.yaml").
        to_return(:body => fixture("web_hooks.yaml"))
    end

    it "should list the web hooks registered under your account" do
      web_hooks = Gems.web_hooks
      a_get("/api/v1/web_hooks.yaml").
        should have_been_made
      web_hooks['all gems'].first['url'].should == "http://example.com"
    end
  end

  describe ".add_web_hook" do
    before do
      stub_post("/api/v1/web_hooks").
        with(:body => {:gem_name => "*", :url => "http://example.com"}).
        to_return(:body => fixture("add_web_hook"))
    end

    it "should add a web hook" do
      add_web_hook = Gems.add_web_hook("*", "http://example.com")
      a_post("/api/v1/web_hooks").
        with(:body => {:gem_name => "*", :url => "http://example.com"}).
        should have_been_made
      add_web_hook.should == "Successfully created webhook for all gems to http://example.com"
    end
  end

  describe ".remove_web_hook" do
    before do
      stub_delete("/api/v1/web_hooks/remove").
        with(:query => {:gem_name => "*", :url => "http://example.com"}).
        to_return(:body => fixture("remove_web_hook"))
    end

    it "should remove a web hook" do
      remove_web_hook = Gems.remove_web_hook("*", "http://example.com")
      a_delete("/api/v1/web_hooks/remove").
        with(:query => {:gem_name => "*", :url => "http://example.com"}).
        should have_been_made
      remove_web_hook.should == "Successfully removed webhook for all gems to http://example.com"
    end
  end

  describe ".fire_web_hook" do
    before do
      stub_post("/api/v1/web_hooks/fire").
        with(:body => {:gem_name => "*", :url => "http://example.com"}).
        to_return(:body => fixture("fire_web_hook"))
    end

    it "should fire a web hook" do
      fire_web_hook = Gems.fire_web_hook("*", "http://example.com")
      a_post("/api/v1/web_hooks/fire").
        with(:body => {:gem_name => "*", :url => "http://example.com"}).
        should have_been_made
      fire_web_hook.should == "Successfully deployed webhook for gemcutter to http://example.com"
    end
  end

  describe ".push" do
    before do
      stub_post("/api/v1/gems").
        to_return(:body => fixture("push"))
    end

    it "should submit a gem to RubyGems.org" do
      push = Gems.push(File.new(File.expand_path("../../fixtures/gems-0.0.8.gem", __FILE__), "rb"))
      a_post("/api/v1/gems").
        should have_been_made
      push.should == "Successfully registered gem: gems (0.0.8)"
    end
  end

  describe ".yank" do
    context "with no version specified" do
      before do
        stub_get("/api/v1/gems/gems.yaml").
          to_return(:body => fixture("rails.yaml"))
        stub_delete("/api/v1/gems/yank").
          with(:query => {:gem_name => "gems", :version => "3.0.9"}).
          to_return(:body => fixture("yank"))
      end

      it "should remove a gem from RubyGems.org's index" do
        yank = Gems.yank("gems")
        a_delete("/api/v1/gems/yank").
          with(:query => {:gem_name => "gems", :version => "3.0.9"}).
          should have_been_made
        yank.should == "Successfully yanked gem: gems (0.0.8)"
      end
    end

    context "with a version specified" do
      before do
        stub_delete("/api/v1/gems/yank").
          with(:query => {:gem_name => "gems", :version => "0.0.8"}).
          to_return(:body => fixture("yank"))
      end

      it "should remove a gem from RubyGems.org's index" do
        yank = Gems.yank("gems", "0.0.8")
        a_delete("/api/v1/gems/yank").
          with(:query => {:gem_name => "gems", :version => "0.0.8"}).
          should have_been_made
        yank.should == "Successfully yanked gem: gems (0.0.8)"
      end
    end
  end

  describe ".unyank" do
    context "with no version specified" do
      before do
        stub_get("/api/v1/gems/gems.yaml").
          to_return(:body => fixture("rails.yaml"))
        stub_put("/api/v1/gems/unyank").
          with(:body => {:gem_name => "gems", :version => "3.0.9"}).
          to_return(:body => fixture("unyank"))
      end

      it "should update a previously yanked gem back into RubyGems.org's index" do
        unyank = Gems.unyank("gems")
        a_put("/api/v1/gems/unyank").
          with(:body => {:gem_name => "gems", :version => "3.0.9"}).
          should have_been_made
        unyank.should == "Successfully unyanked gem: gems (0.0.8)"
      end
    end

    context "with a version specified" do
      before do
        stub_put("/api/v1/gems/unyank").
          with(:body => {:gem_name => "gems", :version => "0.0.8"}).
          to_return(:body => fixture("unyank"))
      end

      it "should update a previously yanked gem back into RubyGems.org's index" do
        unyank = Gems.unyank("gems", "0.0.8")
        a_put("/api/v1/gems/unyank").
          with(:body => {:gem_name => "gems", :version => "0.0.8"}).
          should have_been_made
        unyank.should == "Successfully unyanked gem: gems (0.0.8)"
      end
    end
  end
end
