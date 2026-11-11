# frozen_string_literal: true

RSpec.describe Gems::Dependencies do
  let(:resource_class) do
    Class.new(Gems::Resource) do
      include Gems::Dependencies

      attribute :name
    end
  end
  let(:dependencies) { {"runtime" => [{"name" => "thor", "requirements" => ">= 0"}]} }
  let(:resource) { resource_class.new("name" => "rails", "dependencies" => dependencies) }

  describe "#runtime_dependencies" do
    it "returns the runtime dependencies the response carries" do
      expect(resource.runtime_dependencies.map(&:name)).to eq(["thor"])
    end

    it "answers with an empty Array when the response carries a list for the other type alone" do
      resource = resource_class.new("name" => "rails",
        "dependencies" => {"development" => [{"name" => "rspec", "requirements" => ">= 0"}]})

      expect(resource.runtime_dependencies).to eq([])
    end

    it "answers with an empty Array when the response carries no dependencies at all" do
      expect(resource_class.new({}).runtime_dependencies).to eq([])
    end

    it "raises InvalidResponse when the dependencies are not a JSON object" do
      resource = resource_class.new("name" => "rails", "dependencies" => "runtime")

      expect { resource.runtime_dependencies }
        .to raise_error(an_instance_of(Gems::InvalidResponse)
          .and(having_attributes(body: include('"dependencies":"runtime"'),
            message: a_string_ending_with("String does not have #dig method"))))
    end

    it "raises InvalidResponse when the dependencies of the type are not a list" do
      resource = resource_class.new("name" => "rails", "dependencies" => {"runtime" => "thor"})

      expect { resource.runtime_dependencies }.to raise_error(Gems::InvalidResponse)
    end

    it "attaches the dependency that cannot be read to the error" do
      resource = resource_class.new("name" => "rails", "dependencies" => {"runtime" => ["thor"]})

      expect { resource.runtime_dependencies }
        .to raise_error(having_attributes(body: "thor"))
    end
  end

  describe "#development_dependencies" do
    it "returns the development dependencies the response carries" do
      resource = resource_class.new("name" => "rails",
        "dependencies" => {"development" => [{"name" => "rspec", "requirements" => ">= 0"}]})

      expect(resource.development_dependencies.map(&:name)).to eq(["rspec"])
    end
  end
end
