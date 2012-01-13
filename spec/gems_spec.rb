require 'helper'

describe Gems do
  after do
    Gems.reset
  end

  context "when delegating to a client" do
    before do
      stub_get("/api/v1/gems/rails.yaml").
        to_return(:body => fixture("rails.yaml"))
    end

    it "should get the correct resource" do
      Gems.info('rails')
      a_get("/api/v1/gems/rails.yaml").should have_been_made
    end

    it "should return the same results as a client" do
      Gems.info('rails').should == Gems::Client.new.info('rails')
    end
  end

  describe '.respond_to?' do
    it 'should take an optional argument' do
      Gems.respond_to?(:new, true).should be_true
    end
  end

  describe ".new" do
    it "should return a Gems::Client" do
      Gems.new.should be_a Gems::Client
    end
  end

  describe ".host" do
    it "should return the default host" do
      Gems.host.should == Gems::Configuration::DEFAULT_HOST
    end
  end

  describe ".host=" do
    it "should set the host" do
      Gems.host = 'http://localhost:3000'
      Gems.host.should == 'http://localhost:3000'
    end
  end

  describe ".user_agent" do
    it "should return the default user agent" do
      Gems.user_agent.should == Gems::Configuration::DEFAULT_USER_AGENT
    end
  end

  describe ".user_agent=" do
    it "should set the user agent" do
      Gems.user_agent = 'Custom User Agent'
      Gems.user_agent.should == 'Custom User Agent'
    end
  end

  describe ".configure" do
    Gems::Configuration::VALID_OPTIONS_KEYS.each do |key|
      it "should set the #{key}" do
        Gems.configure do |config|
          config.send("#{key}=", key)
          Gems.send(key).should == key
        end
      end
    end
  end

end
