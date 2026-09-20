# frozen_string_literal: true

RSpec.describe Gems::TrustedPublisher do
  subject(:trusted_publisher) { described_class.new(JSON.parse(fixture("trusted_publisher.json").read)) }

  it "is a Resource" do
    expect(trusted_publisher).to be_a(Gems::Resource)
  end

  it "is identified by its id" do
    expect(trusted_publisher.identity).to eq([1])
  end

  it "inspects as the id and name" do
    expect(trusted_publisher.inspect)
      .to eq('#<Gems::TrustedPublisher id=1 name="GitHub Actions rubygems/gems @ .github/workflows/push_gem.yml">')
  end

  describe ".publisher_attribute" do
    let(:subclass) { Class.new(described_class) { publisher_attribute :repository } }

    it "defines a reader for an attribute of the publisher" do
      expect(subclass.new("trusted_publisher" => {"repository" => "rubygems/gems"}).repository).to eq("rubygems/gems")
    end

    it "reads the attribute by name" do
      expect(subclass.new("trusted_publisher" => {"other" => "rubygems/gems"}).repository).to be_nil
    end

    it "returns nil when the publisher does not carry the attribute" do
      expect(subclass.new("trusted_publisher" => {}).repository).to be_nil
    end

    it "reads the publisher rather than the record it is nested in" do
      expect(subclass.new("repository" => "rubygems/gems", "trusted_publisher" => {}).repository).to be_nil
    end

    it "records the reader in attribute_names" do
      expect(subclass.attribute_names).to eq([*described_class.attribute_names, :repository])
    end

    it "returns the name of the reader" do
      reader = nil
      Class.new(described_class) { reader = publisher_attribute :repository }

      expect(reader).to eq(:repository)
    end
  end

  it "exposes the id" do
    expect(trusted_publisher.id).to eq(1)
  end

  it "exposes the type" do
    expect(trusted_publisher.type).to eq(described_class::GITHUB_ACTION)
  end

  it "exposes the name" do
    expect(trusted_publisher.name).to eq("GitHub Actions rubygems/gems @ .github/workflows/push_gem.yml")
  end

  it "exposes the repository owner" do
    expect(trusted_publisher.repository_owner).to eq("rubygems")
  end

  it "exposes the repository owner ID" do
    expect(trusted_publisher.repository_owner_id).to eq("3430433")
  end

  it "exposes the repository name" do
    expect(trusted_publisher.repository_name).to eq("gems")
  end

  it "exposes the workflow filename" do
    expect(trusted_publisher.workflow_filename).to eq("push_gem.yml")
  end

  it "exposes the environment" do
    expect(described_class.new("trusted_publisher" => {"environment" => "production"}).environment).to eq("production")
  end

  it "exposes no environment when the workflow runs in any" do
    expect(trusted_publisher.environment).to be_nil
  end

  it "exposes the owner of the repository of a reusable workflow" do
    expect(described_class.new("trusted_publisher" => {"workflow_repository_owner" => "rubygems"})
      .workflow_repository_owner).to eq("rubygems")
  end

  it "exposes the name of the repository of a reusable workflow" do
    expect(described_class.new("trusted_publisher" => {"workflow_repository_name" => "workflows"})
      .workflow_repository_name).to eq("workflows")
  end

  it "exposes the attributes of the publisher" do
    expect(trusted_publisher.publisher["repository_owner"]).to eq("rubygems")
  end

  it "exposes no attributes for a record without a publisher" do
    expect(described_class.new("id" => 1).publisher).to eq({})
  end

  it "reads nothing from a record without a publisher" do
    expect(described_class.new("id" => 1).repository_owner).to be_nil
  end

  it "matches a pattern by its readers, including those of the publisher" do
    matched = case trusted_publisher
    in {id: 1, workflow_filename:} then workflow_filename
    end

    expect(matched).to eq("push_gem.yml")
  end

  it "declares the readers it defines" do
    expect(described_class.attribute_names).to eq(%i[id type name repository_owner repository_owner_id repository_name
      workflow_filename environment workflow_repository_owner workflow_repository_name])
  end
end
