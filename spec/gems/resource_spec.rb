RSpec.describe Gems::Resource do
  let(:resource_class) do
    Class.new(described_class) do
      attribute :name
      attribute :key, "rubygems_api_key"
      attribute :sha, "sha", "sha256"
      predicate :yanked
      predicate :indexed, "is_indexed"
      predicate :removed, "removed", "removed_at"
      time_attribute :created_at
      time_attribute :updated_at, "last_updated"
      time_attribute :built_at, "built_at", "constructed_at"
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

    it "records the reader in attribute_names" do
      klass = Class.new(described_class) { attribute :name }

      expect(klass.attribute_names).to eq([:name])
    end

    it "reads a custom key" do
      expect(resource.key).to eq(TEST_KEY)
    end

    it "returns nil when the attribute is missing" do
      expect(resource_class.new({}).name).to be_nil
    end

    it "reads the first of several keys the response contains" do
      expect(resource_class.new("sha256" => "abc").sha).to eq("abc")
    end

    it "prefers the earlier key when the response contains both" do
      expect(resource_class.new("sha" => "abc", "sha256" => "def").sha).to eq("abc")
    end

    it "prefers a key the response contains over a later one, even when its value is nil" do
      expect(resource_class.new("sha" => nil, "sha256" => "def").sha).to be_nil
    end

    it "returns nil when the response contains none of the keys" do
      expect(resource_class.new({}).sha).to be_nil
    end

    it "returns the name of the reader" do
      expect(resource_class.attribute(:version)).to eq(:version)
    end
  end

  describe ".predicate" do
    it "records the predicate in attribute_names" do
      klass = Class.new(described_class) { predicate :yanked }

      expect(klass.attribute_names).to eq([:yanked?])
    end

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

    it "reads the first of several keys the response contains" do
      expect(resource_class.new("removed_at" => "2023-06-29T20:57:24Z").removed?).to be(true)
    end

    it "returns the name of the reader" do
      expect(resource_class.predicate(:prerelease)).to eq(:prerelease?)
    end
  end

  describe ".time_attribute" do
    it "records the reader in attribute_names" do
      klass = Class.new(described_class) { time_attribute :created_at }

      expect(klass.attribute_names).to eq([:created_at])
    end

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

    it "reads the first of several keys the response contains" do
      expect(resource_class.new("constructed_at" => "2023-06-29T00:00:00Z").built_at).to eq(Time.utc(2023, 6, 29))
    end

    it "returns the name of the reader" do
      expect(resource_class.time_attribute(:pushed_at)).to eq(:pushed_at)
    end

    it "raises InvalidResponse for a string that is not a timestamp" do
      expect { resource_class.new("created_at" => "soon").created_at }
        .to raise_error(Gems::InvalidResponse, '"soon" is not a timestamp')
    end

    it "raises InvalidResponse for a value that is not a string" do
      expect { resource_class.new("created_at" => 1_688_000_000).created_at }
        .to raise_error(Gems::InvalidResponse, "1688000000 is not a timestamp")
    end

    it "attaches the value to the error" do
      expect { resource_class.new("created_at" => 1_688_000_000).created_at }
        .to raise_error(having_attributes(body: "1688000000"))
    end

    it "keeps the parser error as the cause" do
      expect { resource_class.new("created_at" => "soon").created_at }
        .to raise_error(having_attributes(cause: an_instance_of(ArgumentError)))
    end
  end

  describe "#initialize" do
    it "stores the attributes" do
      expect(resource.attributes).to eq(attributes)
    end

    it "leaves the hash it was given mutable" do
      raw = {"metadata" => {"changelog_uri" => +"https://example.com"}, "licenses" => [+"MIT"]}
      resource_class.new(raw)

      expect([raw, raw["metadata"], raw["licenses"], raw["licenses"].first].map(&:frozen?)).to all(be(false))
    end

    it "freezes the attributes" do
      expect(resource.attributes).to be_frozen
    end

    it "freezes nested hashes and their values" do
      resource = resource_class.new("metadata" => {"changelog_uri" => +"https://example.com"})

      expect([resource[:metadata], resource[:metadata]["changelog_uri"]]).to all(be_frozen)
    end

    it "copies nested hashes entry by entry" do
      resource = resource_class.new("metadata" => {"changelog_uri" => +"https://example.com"})

      expect(resource[:metadata]).to eq("changelog_uri" => "https://example.com")
    end

    it "freezes nested arrays and their elements" do
      resource = resource_class.new("licenses" => [+"MIT"])

      expect([resource[:licenses], resource[:licenses].first]).to all(be_frozen)
    end

    it "copies nested arrays element by element" do
      expect(resource_class.new("licenses" => [+"MIT"])[:licenses]).to eq(["MIT"])
    end

    it "freezes strings" do
      expect(resource_class.new("name" => +"rails").name).to be_frozen
    end

    it "converts symbol keys to strings" do
      expect(resource_class.new(name: "rails").name).to eq("rails")
    end

    it "converts the symbol keys of nested hashes to strings" do
      resource = resource_class.new(metadata: {changelog_uri: "https://example.com"})

      expect(resource[:metadata]).to eq("changelog_uri" => "https://example.com")
    end
  end

  describe ".attribute_names" do
    it "lists the declared readers in order" do
      expect(resource_class.attribute_names)
        .to eq(%i[name key sha yanked? indexed? removed? created_at updated_at built_at])
    end

    it "is empty for a class that declares nothing" do
      expect(Class.new(described_class).attribute_names).to eq([])
    end

    it "keeps record_attribute private" do
      expect(resource_class).not_to respond_to(:record_attribute)
    end

    it "does not share names between classes" do
      Class.new(described_class) { attribute :other }

      expect(resource_class.attribute_names).not_to include(:other)
    end

    it "is inherited by a subclass that declares nothing" do
      expect(Class.new(resource_class).attribute_names).to eq(resource_class.attribute_names)
    end

    it "appends the names a subclass declares to the inherited ones" do
      declaring = Class.new(resource_class) { attribute :number }

      expect(declaring.attribute_names).to eq([*resource_class.attribute_names, :number])
    end

    it "keeps the names a subclass declares out of its superclass" do
      Class.new(resource_class) { attribute :number }

      expect(resource_class.attribute_names).not_to include(:number)
    end
  end

  describe "a subclass of a resource" do
    let(:subclass) { Class.new(resource_class) }

    it "matches a pattern by the inherited readers" do
      matched = case subclass.new(attributes)
      in {name:, yanked?: true} then name
      end

      expect(matched).to eq("rails")
    end

    it "compares by the inherited identity" do
      identified = Class.new(Class.new(resource_class) { identified_by :name })

      expect(identified.new(attributes)).to eq(identified.new("name" => "rails"))
    end
  end

  describe "#deconstruct_keys" do
    it "reads every declared attribute for nil" do
      expect(resource.deconstruct_keys(nil)).to eq(name: "rails", key: TEST_KEY, sha: nil, yanked?: true, indexed?: false,
        removed?: false, created_at: Time.utc(2023, 6, 29, 20, 57, 24), updated_at: nil, built_at: nil)
    end

    it "reads only the attributes a pattern asks for" do
      expect(resource.deconstruct_keys(%i[name yanked?])).to eq(name: "rails", yanked?: true)
    end

    it "leaves out names it does not declare" do
      expect(resource.deconstruct_keys(%i[name other])).to eq(name: "rails")
    end

    it "matches a case/in pattern" do
      matched = case resource
      in {name: "rails", created_at: Time => created_at} then created_at
      end

      expect(matched).to eq(Time.utc(2023, 6, 29, 20, 57, 24))
    end

    it "does not match a pattern with another value" do
      matched = (resource in {name: "thor"})

      expect(matched).to be(false)
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

    it "is inherited by a subclass that declares nothing" do
      expect(Class.new(resource_class).inspect_readers).to eq(%i[name yanked?])
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

  describe ".identified_by" do
    let(:identified_class) { Class.new(resource_class) { identified_by :name } }

    it "declares the readers that identify the resource" do
      expect(identified_class.identity_readers).to eq(%i[name])
    end

    it "returns the readers" do
      expect(Class.new(described_class).identified_by(:name, :number)).to eq(%i[name number])
    end
  end

  describe ".identity_readers" do
    it "returns the declared readers" do
      expect(Class.new(resource_class) { identified_by :name, :yanked? }.identity_readers).to eq(%i[name yanked?])
    end

    it "defaults to no readers" do
      expect(resource_class.identity_readers).to eq([])
    end

    it "is inherited by a subclass that declares nothing" do
      identified = Class.new(resource_class) { identified_by :name }

      expect(Class.new(identified).identity_readers).to eq(%i[name])
    end
  end

  describe "#identity" do
    it "is the attributes without declared readers" do
      expect(resource.identity).to eq(attributes)
    end

    it "is the values of the declared readers" do
      identified_class = Class.new(resource_class) { identified_by :name, :yanked? }

      expect(identified_class.new(attributes).identity).to eq(["rails", true])
    end
  end

  describe "#to_h" do
    it "returns the attributes" do
      expect(resource.to_h).to eq(attributes)
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

    context "with an identity" do
      let(:identified_class) { Class.new(resource_class) { identified_by :name } }

      it "is true when the identity matches despite other attributes" do
        expect(identified_class.new("name" => "rails", "yanked" => true)).to eq(identified_class.new("name" => "rails"))
      end

      it "is false when the identity differs" do
        expect(identified_class.new("name" => "rails")).not_to eq(identified_class.new("name" => "thor"))
      end
    end
  end

  describe "#eql?" do
    it "is true for the same class and attributes" do
      expect(resource).to eql(resource_class.new(attributes.dup))
    end

    it "is false for different attributes" do
      expect(resource).not_to eql(resource_class.new({}))
    end

    it "compares attribute values with eql?" do
      expect(resource_class.new("downloads" => 1)).not_to eql(resource_class.new("downloads" => 1.0))
    end

    it "is false for a different class with the same attributes" do
      expect(resource).not_to eql(Class.new(described_class).new(attributes))
    end

    it "is false for a subclass with the same attributes" do
      expect(resource).not_to eql(Class.new(resource_class).new(attributes))
    end

    it "is false for a non-resource" do
      expect(resource).not_to eql(attributes)
    end

    it "is true when the identity matches despite other attributes" do
      identified_class = Class.new(resource_class) { identified_by :name }

      expect(identified_class.new("name" => "rails", "yanked" => true)).to eql(identified_class.new("name" => "rails"))
    end
  end

  describe "#hash" do
    it "is equal for equal resources" do
      expect(resource.hash).to eq(resource_class.new(attributes.dup).hash)
    end

    it "differs for different attributes" do
      expect(resource.hash).not_to eq(resource_class.new({}).hash)
    end

    it "differs for attribute values that are == but not eql?" do
      expect(resource_class.new("downloads" => 1).hash).not_to eq(resource_class.new("downloads" => 1.0).hash)
    end

    it "keeps == but not eql? resources distinct in a set" do
      expect(Set[resource_class.new("downloads" => 1), resource_class.new("downloads" => 1.0)].size).to eq(2)
    end

    it "differs for a different class with the same attributes" do
      expect(resource.hash).not_to eq(Class.new(described_class).new(attributes).hash)
    end

    it "deduplicates equal resources in a set" do
      expect(Set[resource, resource_class.new(attributes.dup)].size).to eq(1)
    end

    it "is equal for resources with the same identity" do
      identified_class = Class.new(resource_class) { identified_by :name }

      expect(identified_class.new("name" => "rails", "yanked" => true).hash).to eq(identified_class.new("name" => "rails").hash)
    end
  end
end
