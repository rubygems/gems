# frozen_string_literal: true

RSpec.describe Gems::RedactedOutput do
  subject(:redacted_output) { described_class.new(io) }

  let(:io) { StringIO.new }

  # The headers of a request, as Net::HTTP dumps them to the debug output
  def request_dump(headers)
    %(<- "GET /path HTTP/1.1\\r\\n#{headers.map { |name, value| "#{name}: #{value}\\r\\n" }.join}\\r\\n")
  end

  # The CONNECT request that opens a TLS connection through a proxy, which Net::HTTP writes to the debug output as
  # the buffer it sends rather than as an escaped string
  def connect_dump(headers)
    "CONNECT rubygems.org:443 HTTP/1.1\r\nHost: rubygems.org:443\r\n" \
      "#{headers.map { |name, value| "#{name}: #{value}\r\n" }.join}\r\n"
  end

  describe "#output" do
    it "is the IO the output is written to" do
      expect(redacted_output.output).to equal(io)
    end
  end

  describe "#<<" do
    it "returns itself, so that writes can be chained" do
      expect(redacted_output << "opening connection to rubygems.org:443...\n").to equal(redacted_output)
    end

    it "writes output without a credential unchanged" do
      redacted_output << "opening connection to rubygems.org:443...\n"

      expect(io.string).to eq("opening connection to rubygems.org:443...\n")
    end

    it "redacts the Authorization header" do
      redacted_output << request_dump("Authorization" => "rubygems_701243f217cdf23b1370c7b66b65ca97")

      expect(io.string).to eq(request_dump("Authorization" => "[REDACTED]"))
    end

    it "redacts basic authentication in the Authorization header" do
      redacted_output << request_dump("Authorization" => "Basic bmljazpzY2h3d3d3aW5n")

      expect(io.string).to eq(request_dump("Authorization" => "[REDACTED]"))
    end

    it "redacts the Proxy-Authorization header a request sent through a proxy carries" do
      redacted_output << request_dump("Proxy-Authorization" => "Basic dXNlcjpwYXNzd29yZA==")

      expect(io.string).to eq(request_dump("Proxy-Authorization" => "[REDACTED]"))
    end

    it "redacts the Proxy-Authorization header of the CONNECT that opens a TLS connection through a proxy" do
      redacted_output << connect_dump("Proxy-Authorization" => "Basic dXNlcjpwYXNzd29yZA==")

      expect(io.string).to eq(connect_dump("Proxy-Authorization" => "[REDACTED]"))
    end

    it "keeps the lines of a CONNECT that carry no credential" do
      redacted_output << connect_dump({})

      expect(io.string).to eq(connect_dump({}))
    end

    it "redacts the one-time passcode header Net::HTTP capitalizes as Otp" do
      redacted_output << request_dump("Otp" => "123456")

      expect(io.string).to eq(request_dump("Otp" => "[REDACTED]"))
    end

    it "redacts every credential header of a request" do
      redacted_output << request_dump("Authorization" => "KEY", "Otp" => "123456")

      expect(io.string).to eq(request_dump("Authorization" => "[REDACTED]", "Otp" => "[REDACTED]"))
    end

    it "keeps the headers that carry no credential" do
      redacted_output << request_dump("User-Agent" => "Gems 3.0.0", "Authorization" => "KEY")

      expect(io.string).to eq(request_dump("User-Agent" => "Gems 3.0.0", "Authorization" => "[REDACTED]"))
    end

    it "redacts the ID token of a token exchange body" do
      redacted_output << %(<- "{\\"jwt\\":\\"eyJhbGciOiJSUzI1NiJ9\\"}")

      expect(io.string).to eq(%(<- "{\\"jwt\\":\\"[REDACTED]\\"}"))
    end

    it "redacts the API key a form body carries" do
      redacted_output << %(<- "api_key=rubygems_701243f217cdf23b1370c7b66b65ca97")

      expect(io.string).to eq(%(<- "api_key=[REDACTED]"))
    end

    it "keeps the form fields that carry no credential" do
      redacted_output << %(<- "yank_rubygem=true&api_key=rubygems_701243f217cdf23b1370c7b66b65ca97&name=ci-push")

      expect(io.string).to eq(%(<- "yank_rubygem=true&api_key=[REDACTED]&name=ci-push"))
    end

    it "redacts the API key a response body carries" do
      redacted_output << %(-> "{\\"name\\":\\"ci-push\\",\\"rubygems_api_key\\":\\"rubygems_701243f2\\"}")

      expect(io.string).to eq(%(-> "{\\"name\\":\\"ci-push\\",\\"rubygems_api_key\\":\\"[REDACTED]\\"}"))
    end

    it "does not redact a header that only looks like one, without the escaped newline" do
      redacted_output << '-> "X-Note: Authorization: not a header\\r\\n"'

      expect(io.string).to eq('-> "X-Note: Authorization: not a header\\r\\n"')
    end
  end
end
