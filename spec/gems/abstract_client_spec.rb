RSpec.describe Gems::AbstractClient do
  let(:delegating_module) do
    Module.new do
      include Gems::AbstractClient

      def self.new(...)
        Gems::Client.new(...)
      end
    end
  end
  let(:abstract_module) { Module.new { include Gems::AbstractClient } }

  describe ".included" do
    it "extends the including module with the class methods" do
      expect(abstract_module.singleton_class).to include(described_class::ClassMethods)
    end
  end

  describe "#new" do
    it "raises NotImplementedError unless overridden" do
      expect { abstract_module.new }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError regardless of arguments" do
      expect { abstract_module.new(key: TEST_KEY) }.to raise_error(NotImplementedError)
    end
  end

  describe "#method_missing" do
    before { stub_get("/api/v1/gems/rails.json").to_return(body: fixture("rails.json")) }

    it "delegates to a new client" do
      expect(delegating_module.info("rails")["name"]).to eq("rails")
    end

    it "passes arguments and blocks through" do
      stub_get("/api/v1/search.json?query=cucumber&page=2").to_return(body: fixture("search.json"))
      delegating_module.search("cucumber", page: 2)

      expect(a_get("/api/v1/search.json?query=cucumber&page=2")).to have_been_made
    end

    it "raises NoMethodError for methods the client does not respond to" do
      expect { delegating_module.foo }.to raise_error(NoMethodError)
    end

    it "raises NoMethodError for private client methods" do
      expect { delegating_module.initialize_authenticator }.to raise_error(NoMethodError)
    end
  end

  describe "#respond_to?" do
    it "is true for public client methods" do
      expect(delegating_module.respond_to?(:info)).to be(true)
    end

    it "is true for the module's own methods" do
      expect(delegating_module.respond_to?(:new)).to be(true)
    end

    it "is false for undefined methods" do
      expect(delegating_module.respond_to?(:foo)).to be(false)
    end

    it "is false for private client methods by default" do
      expect(delegating_module.respond_to?(:initialize_authenticator)).to be(false)
    end

    it "is true for private client methods when private methods are included" do
      expect(delegating_module.respond_to?(:initialize_authenticator, true)).to be(true)
    end
  end

  describe "#respond_to_missing?" do
    it "is true for public client methods" do
      expect(delegating_module.send(:respond_to_missing?, :info)).to be(true)
    end

    it "is false for undefined methods" do
      expect(delegating_module.send(:respond_to_missing?, :foo)).to be(false)
    end

    it "is false for private client methods by default" do
      expect(delegating_module.send(:respond_to_missing?, :initialize_authenticator)).to be(false)
    end

    it "is true for private client methods when private methods are included" do
      expect(delegating_module.send(:respond_to_missing?, :initialize_authenticator, true)).to be(true)
    end

    it "lets Object#method find delegated methods" do
      expect(delegating_module.method(:info)).to be_a(Method)
    end
  end
end
