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

    it "gets the correct resource" do
      Gems.info('rails')
      expect(a_get("/api/v1/gems/rails.yaml")).to have_been_made
    end

    it "returns the same results as a client" do
      expect(Gems.info('rails')).to eq Gems::Client.new.info('rails')
    end
  end

  describe '.respond_to?' do
    it "takes an optional argument" do
      expect(Gems.respond_to?(:new, true)).to be_true
    end
  end

  describe ".new" do
    it "returns a Gems::Client" do
      expect(Gems.new).to be_a Gems::Client
    end
  end

  describe ".host" do
    it "returns the default host" do
      expect(Gems.host).to eq Gems::Configuration::DEFAULT_HOST
    end
  end

  describe ".host=" do
    it "sets the host" do
      Gems.host = 'http://localhost:3000'
      expect(Gems.host).to eq 'http://localhost:3000'
    end
  end

  describe ".user_agent" do
    it "returns the default user agent" do
      expect(Gems.user_agent).to eq Gems::Configuration::DEFAULT_USER_AGENT
    end
  end

  describe ".user_agent=" do
    it "sets the user agent" do
      Gems.user_agent = 'Custom User Agent'
      expect(Gems.user_agent).to eq 'Custom User Agent'
    end
  end

  describe ".configure" do
    Gems::Configuration::VALID_OPTIONS_KEYS.each do |key|
      it "sets the #{key}" do
        Gems.configure do |config|
          config.send("#{key}=", key)
          expect(Gems.send(key)).to eq key
        end
      end
    end
  end

end
