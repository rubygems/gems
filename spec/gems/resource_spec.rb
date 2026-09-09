RSpec.describe Gems::Resource do
  let(:resource_class) do
    Class.new(described_class) do
      attribute :name
      attribute :key, "rubygems_api_key"
      predicate :yanked
      predicate :indexed, "is_indexed"
      time_attribute :created_at
      time_attribute :updated_at, "last_updated"
      inspect_with :name, :yanked?
    end
  end
  let(:attributes) { {"name" => "rails", "rubygems_api_key" => TEST_KEY, "yanked" => true, "created_at" => "2023-06-29T20:57:24Z"} }
  let(:resource) { resource_class.new(attributes) }

  describe ".list" do
    it "builds a resource for each attribute hash" do
      list = resource_class.list([attributes, {"name" => "thor"}])

      expect(list.map(&:name)).to eq(%w[rails thor])
    end

    it "builds instances of the class" do
      expect(resource_class.list([attributes])).to all(be_an_instance_of(resource_class))
    end

    it "returns an empty array for an empty list" do
      expect(resource_class.list([])).to eq([])
    end
  end

  describe ".attribute" do
    it "defines a reader for the attribute" do
      expect(resource.name).to eq("rails")
    end

    it "reads a custom key" do
      expect(resource.key).to eq(TEST_KEY)
    end

    it "returns nil when the attribute is missing" do
      expect(resource_class.new({}).name).to be_nil
    end

    it "returns the name of the reader" do
      expect(resource_class.attribute(:version)).to eq(:version)
    end
  end

  describe ".predicate" do
    it "defines a predicate for the attribute" do
      expect(resource.yanked?).to be(true)
    end

    it "returns false when the attribute is false" do
      expect(resource_class.new("yanked" => false).yanked?).to be(false)
    end

    it "returns false when the attribute is missing" do
      expect(resource_class.new({}).yanked?).to be(false)
    end

    it "returns true for any truthy value" do
      expect(resource_class.new("yanked" => "yes").yanked?).to be(true)
    end

    it "reads a custom key" do
      expect(resource_class.new("is_indexed" => true).indexed?).to be(true)
    end

    it "returns the name of the reader" do
      expect(resource_class.predicate(:prerelease)).to eq(:prerelease?)
    end
  end

  describe ".time_attribute" do
    it "parses the attribute as a time" do
      expect(resource.created_at).to eq(Time.utc(2023, 6, 29, 20, 57, 24))
    end

    it "parses non-ISO 8601 timestamps" do
      expect(resource_class.new("created_at" => "2011-09-16 23:01:28 UTC").created_at).to eq(Time.utc(2011, 9, 16, 23, 1, 28))
    end

    it "returns nil when the attribute is missing" do
      expect(resource_class.new({}).created_at).to be_nil
    end

    it "reads a custom key" do
      expect(resource_class.new("last_updated" => "2023-06-29T00:00:00Z").updated_at).to eq(Time.utc(2023, 6, 29))
    end

    it "returns the name of the reader" do
      expect(resource_class.time_attribute(:built_at)).to eq(:built_at)
    end
  end

  describe "#initialize" do
    it "stores the attributes" do
      expect(resource.attributes).to equal(attributes)
    end

    it "freezes the attributes" do
      expect(resource.attributes).to be_frozen
    end

    it "freezes nested hashes and their values" do
      resource = resource_class.new("metadata" => {"changelog_uri" => +"https://example.com"})

      expect([resource[:metadata], resource[:metadata]["changelog_uri"]]).to all(be_frozen)
    end

    it "freezes nested arrays and their elements" do
      resource = resource_class.new("licenses" => [+"MIT"])

      expect([resource[:licenses], resource[:licenses].first]).to all(be_frozen)
    end

    it "freezes strings" do
      expect(resource_class.new("name" => +"rails").name).to be_frozen
    end
  end

  describe "#[]" do
    it "reads a raw attribute by string key" do
      expect(resource["rubygems_api_key"]).to eq(TEST_KEY)
    end

    it "reads a raw attribute by symbol key" do
      expect(resource[:rubygems_api_key]).to eq(TEST_KEY)
    end

    it "returns nil for a missing key" do
      expect(resource["missing"]).to be_nil
    end
  end

  describe ".inspect_with" do
    it "declares the readers shown by inspect" do
      expect(resource_class.inspect_readers).to eq(%i[name yanked?])
    end

    it "returns the readers" do
      expect(Class.new(described_class).inspect_with(:name, :number)).to eq(%i[name number])
    end
  end

  describe ".inspect_readers" do
    it "returns the declared readers" do
      expect(resource_class.inspect_readers).to eq(%i[name yanked?])
    end

    it "defaults to no readers" do
      expect(Class.new(described_class).inspect_readers).to eq([])
    end
  end

  describe "#inspect" do
    it "shows the class and the declared readers" do
      stub_const("Gems::TestResource", resource_class)

      expect(resource.inspect).to eq('#<Gems::TestResource name="rails" yanked?=true>')
    end

    it "shows only the class without declared readers" do
      stub_const("Gems::TestResource", Class.new(described_class))

      expect(Gems::TestResource.new(attributes).inspect).to eq("#<Gems::TestResource>")
    end

    it "shows nil for missing attributes" do
      stub_const("Gems::TestResource", resource_class)

      expect(resource_class.new({}).inspect).to eq("#<Gems::TestResource name=nil yanked?=false>")
    end
  end

  describe "#to_h" do
    it "returns the attributes" do
      expect(resource.to_h).to equal(attributes)
    end
  end

  describe "#==" do
    it "is true for the same class and attributes" do
      expect(resource).to eq(resource_class.new(attributes.dup))
    end

    it "is false for different attributes" do
      expect(resource).not_to eq(resource_class.new("name" => "thor"))
    end

    it "compares attribute values with ==" do
      expect(resource_class.new("downloads" => 1)).to eq(resource_class.new("downloads" => 1.0))
    end

    it "is false for a different class with the same attributes" do
      expect(resource).not_to eq(Class.new(described_class).new(attributes))
    end

    it "is false for a subclass with the same attributes" do
      expect(resource).not_to eq(Class.new(resource_class).new(attributes))
    end

    it "is false for a non-resource" do
      expect(resource).not_to eq(attributes)
    end
  end

  describe "#eql?" do
    it "matches ==" do
      expect(resource).to eql(resource_class.new(attributes.dup))
    end

    it "is false for different attributes" do
      expect(resource).not_to eql(resource_class.new({}))
    end
  end

  describe "#hash" do
    it "is equal for equal resources" do
      expect(resource.hash).to eq(resource_class.new(attributes.dup).hash)
    end

    it "differs for different attributes" do
      expect(resource.hash).not_to eq(resource_class.new({}).hash)
    end

    it "differs for a different class with the same attributes" do
      expect(resource.hash).not_to eq(Class.new(described_class).new(attributes).hash)
    end

    it "deduplicates equal resources in a set" do
      expect(Set[resource, resource_class.new(attributes.dup)].size).to eq(1)
    end
  end
end
