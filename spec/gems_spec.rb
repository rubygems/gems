require 'helper'

describe Gems do
  context "when delegating to a client" do
    before do
      stub_get("/api/v1/gems/rails.json").to_return(:body => fixture("rails.json"))
    end

    it "should get the correct resource" do
      Gems.info('rails')
      a_get("/api/v1/gems/rails.json").should have_been_made
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
end
