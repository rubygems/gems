# frozen_string_literal: true

RSpec.describe Gems::RequestSecrets do
  subject(:reader) { Class.new { include Gems::RequestSecrets }.new }

  # A POST, which carries the credentials of the endpoints that take one in a body, with the headers given and an
  # optional body
  def request(headers = {}, body = nil)
    request = Net::HTTP::Post.new(URI("https://rubygems.org/api/v1/api_key.json"))
    headers.each { |name, value| request[name] = value }
    request.body = body if body
    request
  end

  describe "#secrets_of" do
    it "reads the value of the Authorization header" do
      expect(reader.send(:secrets_of, request("Authorization" => "rubygems_701243f217cdf23b1370c7b66b65ca97")))
        .to eq(["rubygems_701243f217cdf23b1370c7b66b65ca97"])
    end

    it "reads the encoded and decoded credentials of basic authentication, each part of them" do
      expect(reader.send(:secrets_of, request("Authorization" => "Basic bmljazpwYXNzd29yZA==")))
        .to eq(["Basic bmljazpwYXNzd29yZA==", "bmljazpwYXNzd29yZA==", "nick", "password"])
    end

    it "reads the one-time passcode" do
      expect(reader.send(:secrets_of, request("Authorization" => "KEY", "OTP" => "123456")))
        .to eq(["KEY", "123456"])
    end

    it "reads the ID token a JSON body carries as its jwt field" do
      expect(reader.send(:secrets_of, request({}, '{"jwt":"ID_TOKEN"}'))).to eq(["ID_TOKEN"])
    end

    it "reads the API key a form body carries as its api_key field" do
      expect(reader.send(:secrets_of, request({}, "api_key=KEY&push_rubygem=true"))).to eq(["KEY"])
    end

    it "reads nothing from a request without credentials" do
      expect(reader.send(:secrets_of, request)).to eq([])
    end
  end

  describe "#basic_secrets_of" do
    it "reads the username and the password of the credentials given" do
      expect(reader.send(:basic_secrets_of, "bmljazpwYXNzd29yZA==")).to eq(["nick", "password"])
    end

    it "reads a password that holds a colon of its own" do
      expect(reader.send(:basic_secrets_of, "bmljazpwYXNzOndvcmQ=")).to eq(["nick", "pass:word"])
    end

    it "reads nothing from credentials that decode to no colon" do
      expect(reader.send(:basic_secrets_of, "dGVzdA==")).to eq([])
    end

    it "reads nothing from credentials that are not encoded" do
      expect(reader.send(:basic_secrets_of, "!!!")).to eq([])
    end

    it "reads nothing when there are no credentials" do
      expect(reader.send(:basic_secrets_of, nil)).to eq([])
    end
  end

  describe "#body_secrets_of" do
    it "reads the ID token a JSON body carries as its jwt field" do
      expect(reader.send(:body_secrets_of, request({}, '{"jwt":"ID_TOKEN"}'))).to eq(["ID_TOKEN"])
    end

    it "reads the API key a form body carries as its api_key field" do
      expect(reader.send(:body_secrets_of, request({}, "api_key=KEY"))).to eq(["KEY"])
    end

    it "reads nothing from a jwt field of another type than a String" do
      expect(reader.send(:body_secrets_of, request({}, '{"jwt":1}'))).to eq([])
    end

    it "reads nothing from a body that is neither JSON nor a form" do
      expect(reader.send(:body_secrets_of, request({}, "octets"))).to eq([])
    end

    it "reads nothing from a body that is not a String" do
      binary = request
      binary.body = 123

      expect(reader.send(:body_secrets_of, binary)).to eq([])
    end

    it "reads the credentials a body of a class that is a String carries" do
      subclass = Class.new(String)
      string_body = request
      string_body.body = subclass.new('{"jwt":"ID_TOKEN"}')

      expect(reader.send(:body_secrets_of, string_body)).to eq(["ID_TOKEN"])
    end

    it "reads nothing from a body streamed rather than set" do
      streamed = request
      streamed.body = nil
      streamed.body_stream = StringIO.new('{"jwt":"ID_TOKEN"}')

      expect(reader.send(:body_secrets_of, streamed)).to eq([])
    end

    it "reads nothing from a request without a body" do
      expect(reader.send(:body_secrets_of, request)).to eq([])
    end
  end

  describe "#json_secret_of" do
    it "reads the ID token the jwt field carries" do
      expect(reader.send(:json_secret_of, '{"jwt":"ID_TOKEN"}')).to eq("ID_TOKEN")
    end

    it "reads nothing from a body that is not JSON" do
      expect(reader.send(:json_secret_of, "octets")).to be_nil
    end

    it "reads nothing from a JSON body that is not an object" do
      expect(reader.send(:json_secret_of, "[]")).to be_nil
    end

    it "reads nothing from a JSON body that is null" do
      expect(reader.send(:json_secret_of, "null")).to be_nil
    end

    it "reads nothing from a JSON body that carries no jwt field" do
      expect(reader.send(:json_secret_of, "{}")).to be_nil
    end
  end

  describe "#form_secret_of" do
    it "reads the API key the api_key field carries" do
      expect(reader.send(:form_secret_of, "api_key=KEY&push_rubygem=true")).to eq("KEY")
    end

    it "reads nothing from a body that is not a form" do
      expect(reader.send(:form_secret_of, "octets")).to be_nil
    end

    it "reads nothing from a body that carries no api_key field" do
      expect(reader.send(:form_secret_of, "push_rubygem=true")).to be_nil
    end

    it "reads nothing from a body whose encoding cannot be read" do
      expect(reader.send(:form_secret_of, "api_key=\xff".b)).to be_nil
    end
  end
end
