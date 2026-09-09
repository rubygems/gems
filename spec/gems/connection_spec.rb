RSpec.describe Gems::Connection do
  subject(:connection) { described_class.new }

  let(:https_uri) { URI("https://rubygems.org/api/v1/gems/rails.json") }
  let(:http_uri) { URI("http://example.com:8080/path") }

  def with_env(env)
    original = env.keys.to_h { |key| [key, ENV.fetch(key, nil)] }
    env.each { |key, value| ENV[key] = value }
    yield
  ensure
    original.each { |key, value| ENV[key] = value }
  end

  around do |example|
    with_env("http_proxy" => nil, "https_proxy" => nil, "no_proxy" => nil,
      "HTTP_PROXY" => nil, "HTTPS_PROXY" => nil, "NO_PROXY" => nil) { example.run }
  end

  describe "#initialize" do
    it "defaults the open timeout" do
      expect(connection.open_timeout).to eq(described_class::DEFAULT_OPEN_TIMEOUT)
    end

    it "defaults the read timeout" do
      expect(connection.read_timeout).to eq(described_class::DEFAULT_READ_TIMEOUT)
    end

    it "defaults the write timeout" do
      expect(connection.write_timeout).to eq(described_class::DEFAULT_WRITE_TIMEOUT)
    end

    it "defaults the debug output to nil" do
      expect(connection.debug_output).to be_nil
    end

    it "defaults the proxy URL to nil" do
      expect(connection.proxy_url).to be_nil
    end

    it "defaults the proxy URI to nil" do
      expect(connection.proxy_uri).to be_nil
    end

    context "with custom options" do
      subject(:connection) do
        described_class.new(open_timeout: 10, read_timeout: 20, write_timeout: 30, debug_output: $stderr,
          proxy_url: "http://user:pass@proxy.example.com:8080")
      end

      it "sets the open timeout" do
        expect(connection.open_timeout).to eq(10)
      end

      it "sets the read timeout" do
        expect(connection.read_timeout).to eq(20)
      end

      it "sets the write timeout" do
        expect(connection.write_timeout).to eq(30)
      end

      it "sets the debug output" do
        expect(connection.debug_output).to equal($stderr)
      end

      it "sets the proxy URL" do
        expect(connection.proxy_url).to eq("http://user:pass@proxy.example.com:8080")
      end

      it "parses the proxy URI" do
        expect(connection.proxy_uri).to eq(URI("http://user:pass@proxy.example.com:8080"))
      end
    end
  end

  describe "#proxy_url=" do
    before { connection.proxy_url = "https://user:pass@proxy.example.com:8080" }

    it "sets the proxy URL" do
      expect(connection.proxy_url).to eq("https://user:pass@proxy.example.com:8080")
    end

    it "parses the proxy URI" do
      expect(connection.proxy_uri).to eq(URI("https://user:pass@proxy.example.com:8080"))
    end

    it "exposes the proxy host" do
      expect(connection.proxy_host).to eq("proxy.example.com")
    end

    it "exposes the proxy port" do
      expect(connection.proxy_port).to eq(8080)
    end

    it "exposes the proxy user" do
      expect(connection.proxy_user).to eq("user")
    end

    it "exposes the proxy password" do
      expect(connection.proxy_pass).to eq("pass")
    end

    it "raises an ArgumentError for a non-HTTP proxy URL" do
      expect { connection.proxy_url = "ftp://proxy.example.com/" }
        .to raise_error(ArgumentError, "Invalid proxy URL: ftp://proxy.example.com/")
    end
  end

  describe "#perform" do
    it "performs the request" do
      stub_request(:get, https_uri.to_s)
      connection.perform(request: Net::HTTP::Get.new(https_uri))

      expect(a_request(:get, https_uri.to_s)).to have_been_made
    end

    it "returns the response" do
      stub_request(:get, https_uri.to_s).to_return(body: "body")

      expect(connection.perform(request: Net::HTTP::Get.new(https_uri)).body).to eq("body")
    end

    it "connects to the request's host and port" do
      stub_request(:get, http_uri.to_s)
      connection.perform(request: Net::HTTP::Get.new(http_uri))

      expect(a_request(:get, http_uri.to_s)).to have_been_made
    end

    it "does not wrap errors" do
      stub_request(:get, https_uri.to_s).to_raise(Errno::ECONNREFUSED)

      expect { connection.perform(request: Net::HTTP::Get.new(https_uri)) }.to raise_error(Errno::ECONNREFUSED)
    end
  end

  describe "#build_http_client" do
    def build_http_client(uri, connection: self.connection)
      connection.send(:build_http_client, uri)
    end

    it "returns a Net::HTTP client" do
      expect(build_http_client(https_uri)).to be_a(Net::HTTP)
    end

    it "uses the URI's host" do
      expect(build_http_client(http_uri).address).to eq("example.com")
    end

    it "uses the URI's port" do
      expect(build_http_client(http_uri).port).to eq(8080)
    end

    it "uses the default port for the scheme" do
      expect(build_http_client(https_uri).port).to eq(443)
    end

    it "uses SSL for HTTPS URIs" do
      expect(build_http_client(https_uri)).to be_use_ssl
    end

    it "does not use SSL for HTTP URIs" do
      expect(build_http_client(http_uri)).not_to be_use_ssl
    end

    it "raises an ArgumentError for a URI without a host" do
      expect { build_http_client(URI("/path")) }.to raise_error(ArgumentError, "URI has no host: /path")
    end

    it "applies the open timeout" do
      connection = described_class.new(open_timeout: 10)

      expect(build_http_client(https_uri, connection:).open_timeout).to eq(10)
    end

    it "applies the read timeout" do
      connection = described_class.new(read_timeout: 20)

      expect(build_http_client(https_uri, connection:).read_timeout).to eq(20)
    end

    it "applies the write timeout" do
      connection = described_class.new(write_timeout: 30)

      expect(build_http_client(https_uri, connection:).write_timeout).to eq(30)
    end

    it "applies the debug output" do
      connection = described_class.new(debug_output: $stderr)

      expect(build_http_client(https_uri, connection:).instance_variable_get(:@debug_output)).to equal($stderr)
    end

    it "does not set debug output by default" do
      expect(build_http_client(https_uri).instance_variable_get(:@debug_output)).to be_nil
    end

    context "without a proxy" do
      it "does not use a proxy" do
        expect(build_http_client(https_uri)).not_to be_proxy
      end
    end

    context "with a proxy URL" do
      subject(:connection) { described_class.new(proxy_url: "http://user:pass@proxy.example.com:8080") }

      it "uses the proxy" do
        expect(build_http_client(https_uri)).to be_proxy
      end

      it "uses the proxy host" do
        expect(build_http_client(https_uri).proxy_address).to eq("proxy.example.com")
      end

      it "uses the proxy port" do
        expect(build_http_client(https_uri).proxy_port).to eq(8080)
      end

      it "uses the proxy user" do
        expect(build_http_client(https_uri).proxy_user).to eq("user")
      end

      it "uses the proxy password" do
        expect(build_http_client(https_uri).proxy_pass).to eq("pass")
      end

      it "takes precedence over the environment" do
        with_env("https_proxy" => "http://env.example.com:9999") do
          expect(build_http_client(https_uri).proxy_address).to eq("proxy.example.com")
        end
      end
    end

    context "with a proxy in the environment" do
      around { |example| with_env("https_proxy" => "http://env_user:env_pass@env.example.com:9999") { example.run } }

      it "uses the proxy for matching schemes" do
        expect(build_http_client(https_uri)).to be_proxy
      end

      it "uses the proxy host" do
        expect(build_http_client(https_uri).proxy_address).to eq("env.example.com")
      end

      it "uses the proxy port" do
        expect(build_http_client(https_uri).proxy_port).to eq(9999)
      end

      it "uses the proxy user" do
        expect(build_http_client(https_uri).proxy_user).to eq("env_user")
      end

      it "uses the proxy password" do
        expect(build_http_client(https_uri).proxy_pass).to eq("env_pass")
      end

      it "does not use the proxy for other schemes" do
        expect(build_http_client(http_uri)).not_to be_proxy
      end

      it "respects no_proxy" do
        with_env("no_proxy" => "rubygems.org") do
          expect(build_http_client(https_uri)).not_to be_proxy
        end
      end
    end
  end
end
