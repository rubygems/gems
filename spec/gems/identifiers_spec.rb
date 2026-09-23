# frozen_string_literal: true

RSpec.describe Gems::Identifiers do
  let(:client) { Gems::Client.new(key: nil, username: nil, password: nil) }

  describe "#name_of" do
    it "returns a name unchanged" do
      expect(client.send(:name_of, "rails")).to eq("rails")
    end

    it "returns the name of a gem" do
      expect(client.send(:name_of, Gems::Gem.new("name" => "rails"))).to eq("rails")
    end

    it "returns the name of a version" do
      expect(client.send(:name_of, Gems::Version.new("name" => "rails"))).to eq("rails")
    end

    it "returns nil for nil" do
      expect(client.send(:name_of, nil)).to be_nil
    end
  end

  describe "#number_of" do
    it "returns a number unchanged" do
      expect(client.send(:number_of, "7.0.6")).to eq("7.0.6")
    end

    it "returns nil unchanged" do
      expect(client.send(:number_of, nil)).to be_nil
    end

    it "returns the number of a version" do
      expect(client.send(:number_of, Gems::Version.new("number" => "7.0.6"))).to eq("7.0.6")
    end

    it "returns the version of a gem" do
      expect(client.send(:number_of, Gems::Gem.new("name" => "rails", "version" => "7.0.6"))).to eq("7.0.6")
    end
  end

  describe "#version_of" do
    let(:version) { Gems::Version.new("name" => "nokogiri", "number" => "1.15.0", "platform" => "java") }

    it "returns a version unchanged" do
      expect(client.send(:version_of, "nokogiri", "1.15.0")).to eq("1.15.0")
    end

    it "returns the version given as the gem when no version is given" do
      expect(client.send(:version_of, version, nil)).to equal(version)
    end

    it "prefers the version to the version given as the gem" do
      expect(client.send(:version_of, version, "1.16.0")).to eq("1.16.0")
    end

    it "returns nil for a gem name without a version" do
      expect(client.send(:version_of, "nokogiri", nil)).to be_nil
    end

    it "returns the gem given as the gem when it carries a version" do
      gem = Gems::Gem.new("name" => "nokogiri", "version" => "1.15.0")

      expect(client.send(:version_of, gem, nil)).to equal(gem)
    end

    it "returns nil for a gem that carries no version" do
      expect(client.send(:version_of, Gems::Gem.new("name" => "nokogiri"), nil)).to be_nil
    end

    it "returns nil for a version that carries no number" do
      expect(client.send(:version_of, Gems::Version.new("name" => "nokogiri"), nil)).to be_nil
    end
  end

  describe "#platform_of" do
    it "returns nil for a version number" do
      expect(client.send(:platform_of, "7.0.6")).to be_nil
    end

    it "returns the platform of a version" do
      expect(client.send(:platform_of, Gems::Version.new("number" => "1.15.0", "platform" => "java"))).to eq("java")
    end

    it "returns the platform of a gem" do
      expect(client.send(:platform_of, Gems::Gem.new("version" => "1.15.0", "platform" => "java"))).to eq("java")
    end
  end

  describe "#ruby_abi_of" do
    it "returns nil for a version number" do
      expect(client.send(:ruby_abi_of, "7.0.6")).to be_nil
    end

    it "returns the Ruby ABI of a version" do
      expect(client.send(:ruby_abi_of, Gems::Version.new("number" => "1.15.0", "ruby_abi" => "3.4"))).to eq("3.4")
    end

    it "returns the Ruby ABI of a gem" do
      expect(client.send(:ruby_abi_of, Gems::Gem.new("version" => "1.15.0", "ruby_abi" => "3.4"))).to eq("3.4")
    end
  end

  describe "#full_name_of" do
    it "joins the name and number" do
      expect(client.send(:full_name_of, "rails", "7.0.6")).to eq("rails-7.0.6")
    end

    it "appends the platform" do
      expect(client.send(:full_name_of, "nokogiri", "1.15.0", "java")).to eq("nokogiri-1.15.0-java")
    end

    it "omits the ruby platform" do
      expect(client.send(:full_name_of, "rails", "7.0.6", "ruby")).to eq("rails-7.0.6")
    end

    it "defaults to the platform of a version" do
      version = Gems::Version.new("name" => "nokogiri", "number" => "1.15.0", "platform" => "java")

      expect(client.send(:full_name_of, version, version)).to eq("nokogiri-1.15.0-java")
    end

    it "prefers an explicit platform" do
      version = Gems::Version.new("number" => "1.15.0", "platform" => "java")

      expect(client.send(:full_name_of, "nokogiri", version, "x86_64-linux")).to eq("nokogiri-1.15.0-x86_64-linux")
    end

    it "names a version by the full name it carries" do
      version = Gems::Version.new("name" => "nokogiri", "number" => "1.15.0", "platform" => "x86_64-linux",
        "ruby_abi" => "3.4", "full_name" => "nokogiri-1.15.0-a1b2c3d4")

      expect(client.send(:full_name_of, version, version)).to eq("nokogiri-1.15.0-a1b2c3d4")
    end

    it "names a version of a subclass by the full name it carries" do
      version = Class.new(Gems::Version).new("name" => "nokogiri", "number" => "1.15.0", "full_name" => "nokogiri-1.15.0-a1b2c3d4")

      expect(client.send(:full_name_of, version, version)).to eq("nokogiri-1.15.0-a1b2c3d4")
    end

    it "names a version by an explicit platform rather than by the full name it carries" do
      version = Gems::Version.new("number" => "1.15.0", "platform" => "java", "full_name" => "nokogiri-1.15.0-java")

      expect(client.send(:full_name_of, "nokogiri", version, "x86_64-linux")).to eq("nokogiri-1.15.0-x86_64-linux")
    end

    it "does not take the full name of a gem for the full name of a version" do
      gem = Gems::Gem.new("name" => "nokogiri", "version" => "1.15.0", "full_name" => "other-1.0.0")

      expect(client.send(:full_name_of, gem, gem)).to eq("nokogiri-1.15.0")
    end

    it "raises for a version built for a Ruby ABI that carries no full name" do
      version = Gems::Version.new("name" => "nokogiri", "number" => "1.15.0", "platform" => "x86_64-linux", "ruby_abi" => "3.4")

      expect { client.send(:full_name_of, version, version) }
        .to raise_error(ArgumentError, /\A#<Gems::Version .*> was built for Ruby ABI 3\.4, which has no full name to look it up by\z/)
    end

    it "raises for a gem built for a Ruby ABI" do
      gem = Gems::Gem.new("name" => "nokogiri", "version" => "1.15.0", "platform" => "x86_64-linux", "ruby_abi" => "3.4")

      expect { client.send(:full_name_of, gem, gem) }.to raise_error(ArgumentError, /Ruby ABI 3\.4/)
    end
  end

  describe "#handle_of" do
    it "returns a handle unchanged" do
      expect(client.send(:handle_of, "sferik")).to eq("sferik")
    end

    it "returns the handle of an owner" do
      expect(client.send(:handle_of, Gems::Owner.new("handle" => "sferik", "email" => "sferik@gmail.com"))).to eq("sferik")
    end

    it "falls back to the email of an owner without a handle" do
      expect(client.send(:handle_of, Gems::Owner.new("email" => "sferik@gmail.com"))).to eq("sferik@gmail.com")
    end

    it "returns the handle of a profile" do
      expect(client.send(:handle_of, Gems::Profile.new("id" => 1, "handle" => "sferik"))).to eq("sferik")
    end
  end

  describe "#slug_of" do
    it "returns a handle unchanged" do
      expect(client.send(:slug_of, "sferik")).to eq("sferik")
    end

    it "returns the handle of an owner" do
      expect(client.send(:slug_of, Gems::Owner.new("id" => 1, "handle" => "sferik"))).to eq("sferik")
    end

    it "falls back to the ID of an owner without a handle" do
      expect(client.send(:slug_of, Gems::Owner.new("id" => 1, "email" => "sferik@gmail.com"))).to eq(1)
    end

    it "returns the handle of a profile" do
      expect(client.send(:slug_of, Gems::Profile.new("id" => 1, "handle" => "sferik"))).to eq("sferik")
    end
  end

  describe "#url_of" do
    it "returns a URL unchanged" do
      expect(client.send(:url_of, "http://example.com")).to eq("http://example.com")
    end

    it "returns the URL of a web hook" do
      expect(client.send(:url_of, Gems::WebHook.new("url" => "http://example.com"))).to eq("http://example.com")
    end
  end

  describe "#timestamp_of" do
    it "formats a Time as ISO 8601" do
      expect(client.send(:timestamp_of, Time.utc(2019, 1, 18, 21, 24, 29))).to eq("2019-01-18T21:24:29Z")
    end

    it "returns a string unchanged" do
      expect(client.send(:timestamp_of, "2019-01-18T21:24:29Z")).to eq("2019-01-18T21:24:29Z")
    end

    it "returns nil for nil" do
      expect(client.send(:timestamp_of, nil)).to be_nil
    end
  end

  describe "#key_of" do
    it "returns a key unchanged" do
      expect(client.send(:key_of, TEST_KEY)).to eq(TEST_KEY)
    end

    it "returns the key of an API key" do
      expect(client.send(:key_of, Gems::APIKey.new("rubygems_api_key" => TEST_KEY))).to eq(TEST_KEY)
    end

    it "returns nil for nil" do
      expect(client.send(:key_of, nil)).to be_nil
    end
  end

  describe "#id_of" do
    it "returns an ID unchanged" do
      expect(client.send(:id_of, 1)).to eq(1)
    end

    it "returns the ID of a trusted publisher" do
      expect(client.send(:id_of, Gems::TrustedPublisher.new("id" => 1))).to eq(1)
    end

    it "returns nil for nil" do
      expect(client.send(:id_of, nil)).to be_nil
    end
  end
end
