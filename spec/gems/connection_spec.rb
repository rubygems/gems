# frozen_string_literal: true

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

    it "defaults the keep-alive timeout" do
      expect(connection.keep_alive_timeout).to eq(described_class::DEFAULT_KEEP_ALIVE_TIMEOUT)
    end

    it "builds a pool for the connections it keeps open" do
      expect(connection.send(:pool)).to be_an_instance_of(Gems::ConnectionPool)
    end

    it "sets the keep-alive timeout" do
      expect(described_class.new(keep_alive_timeout: 5).keep_alive_timeout).to eq(5)
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

    it "defaults the certificates to nil" do
      expect([connection.ca_file, connection.ca_path, connection.cert_store, connection.client_cert,
        connection.client_key]).to all(be_nil)
    end

    context "with custom options" do
      subject(:connection) do
        described_class.new(open_timeout: 10, read_timeout: 20, write_timeout: 30, debug_output: $stderr,
          proxy_url: "http://user:pass@proxy.example.com:8080", ca_file: certificate_path("ca.pem"),
          ca_path: certificate_path, cert_store: store, client_cert:, client_key:)
      end

      let(:store) { OpenSSL::X509::Store.new }
      let(:client_cert) { test_client_cert }
      let(:client_key) { test_client_key }

      it "sets the certificates" do
        expect([connection.ca_file, connection.ca_path, connection.cert_store, connection.client_cert,
          connection.client_key]).to eq([certificate_path("ca.pem"), certificate_path, store, client_cert, client_key])
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

  %i[open_timeout read_timeout write_timeout keep_alive_timeout].each do |setting|
    describe "##{setting}=" do
      it "assigns a number of seconds" do
        connection.public_send(:"#{setting}=", 0.5)

        expect(connection.public_send(setting)).to eq(0.5)
      end

      it "raises for a negative number of seconds" do
        expect { connection.public_send(:"#{setting}=", -1) }.to raise_error(ArgumentError, "Invalid #{setting}: -1")
      end

      it "raises for a value that is not a number" do
        expect { connection.public_send(:"#{setting}=", "30") }
          .to raise_error(ArgumentError, "Invalid #{setting}: \"30\"")
      end

      it "leaves the setting as it was after a value it refuses" do
        connection.public_send(:"#{setting}=", 30)
        connection.public_send(:"#{setting}=", -1)
      rescue ArgumentError
        expect(connection.public_send(setting)).to eq(30)
      end

      it "refuses the value the connection is built with" do
        expect { described_class.new(setting => -1) }.to raise_error(ArgumentError, "Invalid #{setting}: -1")
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

    it "raises an ArgumentError for a non-HTTP proxy URL" do
      expect { connection.proxy_url = "ftp://proxy.example.com/" }
        .to raise_error(ArgumentError, "Invalid proxy URL: ftp://proxy.example.com/")
    end

    it "raises an ArgumentError for a proxy URL that cannot be parsed" do
      expect { connection.proxy_url = "http://proxy example.com/" }
        .to raise_error(ArgumentError, "Invalid proxy URL: http://proxy example.com/")
    end

    it "leaves the user and password out of the error message" do
      expect { connection.proxy_url = "ftp://user:secret@proxy.example.com/" }
        .to raise_error(ArgumentError, "Invalid proxy URL: ftp://proxy.example.com/")
    end

    it "leaves the proxy as it was after an invalid URL" do
      connection.proxy_url = "ftp://proxy.example.com/"
    rescue ArgumentError
      expect(connection.proxy_uri).to eq(URI("https://user:pass@proxy.example.com:8080"))
    end

    it "leaves the user and password out of the error message for a URL that cannot be parsed" do
      expect { connection.proxy_url = "http://user:secret@proxy example.com/" }
        .to raise_error(ArgumentError, "Invalid proxy URL: http://proxy example.com/")
    end

    context "when set to nil" do
      before { connection.proxy_url = nil }

      it "clears the proxy URL" do
        expect(connection.proxy_url).to be_nil
      end

      it "clears the proxy URI" do
        expect(connection.proxy_uri).to be_nil
      end
    end
  end

  describe "#inspect" do
    it "shows the proxy URL without its user and password" do
      connection.proxy_url = "http://user:secret@proxy.example.com:8080"

      expect(connection.inspect).to eq('#<Gems::Connection proxy_url="http://proxy.example.com:8080" open_timeout=60 ' \
        "read_timeout=60 write_timeout=60 keep_alive_timeout=2>")
    end

    it "shows a proxy URL with an empty user and password without the separator" do
      connection.proxy_url = "http://@proxy.example.com:8080"

      expect(connection.inspect).to include('proxy_url="http://proxy.example.com:8080"')
    end

    it "shows a nil proxy URL" do
      expect(connection.inspect)
        .to eq("#<Gems::Connection proxy_url=nil open_timeout=60 read_timeout=60 write_timeout=60 keep_alive_timeout=2>")
    end

    it "shows the timeouts" do
      connection = described_class.new(open_timeout: 1, read_timeout: 2, write_timeout: 3, keep_alive_timeout: 4)

      expect(connection.inspect)
        .to eq("#<Gems::Connection proxy_url=nil open_timeout=1 read_timeout=2 write_timeout=3 keep_alive_timeout=4>")
    end
  end

  describe "#close" do
    let(:built) { [] }

    before do
      stub_request(:get, https_uri.to_s)
      allow(Net::HTTP).to receive(:new).and_wrap_original do |original, *arguments|
        original.call(*arguments).tap { |http_client| built << http_client }
      end
    end

    it "returns the connection" do
      expect(connection.close).to equal(connection)
    end

    it "closes the connection it keeps open" do
      connection.perform(request: Net::HTTP::Get.new(https_uri))
      connection.close

      expect(built.first).not_to be_started
    end

    it "opens a connection again for the next request" do
      connection.perform(request: Net::HTTP::Get.new(https_uri))
      connection.close
      connection.perform(request: Net::HTTP::Get.new(https_uri))

      expect(built.size).to eq(2)
    end
  end

  describe "#settings" do
    it "names each setting a connection is opened with" do
      connection = described_class.new(debug_output: $stderr, proxy_url: "http://proxy.example.com:8080")

      expect(connection.send(:settings)).to eq(open_timeout: 60, read_timeout: 60, write_timeout: 60,
        keep_alive_timeout: 2, debug_output: $stderr, proxy_url: "http://proxy.example.com:8080",
        certificates: [nil, nil, nil, nil, nil])
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

    [
      EOFError,
      Errno::ECONNABORTED,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::EHOSTUNREACH,
      Errno::ENETUNREACH,
      Errno::EPIPE,
      Errno::ETIMEDOUT,
      EOFError,
      Errno::ECONNRESET,
      IOError,
      Net::HTTPBadResponse,
      Net::OpenTimeout,
      Net::ProtocolError,
      Net::ReadTimeout,
      Net::WriteTimeout,
      OpenSSL::SSL::SSLError,
      SocketError,
      Timeout::Error,
      Zlib::BufError,
      Zlib::DataError
    ].each do |error_class|
      it "wraps #{error_class} in a NetworkError" do
        stub_request(:get, https_uri.to_s).to_raise(error_class)

        expect { connection.perform(request: Net::HTTP::Get.new(https_uri)) }
          .to raise_error(Gems::NetworkError, /\ANetwork error: /)
      end
    end

    it "includes the original error message in the NetworkError" do
      stub_request(:get, https_uri.to_s).to_raise(Errno::ECONNREFUSED)

      expect { connection.perform(request: Net::HTTP::Get.new(https_uri)) }
        .to raise_error(Gems::NetworkError, "Network error: Connection refused - Exception from WebMock")
    end

    it "asks for a response that is not compressed when it has a debug output" do
      stub_request(:get, https_uri.to_s)
      connection.debug_output = StringIO.new
      connection.perform(request: Net::HTTP::Get.new(https_uri))

      expect(a_request(:get, https_uri.to_s).with(headers: {"Accept-Encoding" => "identity"})).to have_been_made
    end

    it "asks for a compressed response without a debug output" do
      stub_request(:get, https_uri.to_s)
      connection.perform(request: Net::HTTP::Get.new(https_uri))

      expect(a_request(:get, https_uri.to_s).with(headers: {"Accept-Encoding" => /gzip/})).to have_been_made
    end

    it "does not wrap other errors" do
      stub_request(:get, https_uri.to_s).to_raise(ArgumentError)

      expect { connection.perform(request: Net::HTTP::Get.new(https_uri)) }.to raise_error(ArgumentError)
    end

    context "when it keeps connections open" do
      let(:built) { [] }

      before do
        stub_request(:get, https_uri.to_s)
        stub_request(:post, https_uri.to_s)
        stub_request(:get, http_uri.to_s)
        allow(Net::HTTP).to receive(:new).and_wrap_original do |original, *arguments|
          original.call(*arguments).tap { |http_client| built << http_client }
        end
      end

      def get(uri = https_uri)
        connection.perform(request: Net::HTTP::Get.new(uri))
      end

      def get_ignoring_errors(uri = https_uri)
        get(uri)
      rescue Gems::NetworkError
        nil
      end

      def get_rescuing(error_class)
        get
      rescue error_class
        nil
      end

      it "sends a second request on the connection the first left open" do
        2.times { get }

        expect(built.size).to eq(1)
      end

      it "opens a connection for each host" do
        get
        get(http_uri)

        expect(built.size).to eq(2)
      end

      it "leaves the connection open" do
        get

        expect(built.first).to be_started
      end

      it "opens a connection of its own for a request that acts on the server" do
        get
        connection.perform(request: Net::HTTP::Post.new(https_uri))

        expect(built.size).to eq(2)
      end

      it "closes the connection of a request that acts on the server" do
        connection.perform(request: Net::HTTP::Post.new(https_uri))

        expect(built.first).not_to be_started
      end

      it "opens a connection for each request when the keep-alive timeout is zero" do
        connection.keep_alive_timeout = 0
        2.times { get }

        expect(built.size).to eq(2)
      end

      {open_timeout: 1, read_timeout: 1, write_timeout: 1, keep_alive_timeout: 1, debug_output: StringIO.new,
       proxy_url: "http://proxy.example.com:8080", ca_file: certificate_path("ca.pem"),
       ca_path: certificate_path, cert_store: OpenSSL::X509::Store.new, client_cert: test_client_cert,
       client_key: test_client_key}.each do |setting, value|
        it "opens a connection again when the #{setting} has changed" do
          get
          connection.public_send(:"#{setting}=", value)
          get

          expect(built.size).to eq(2)
        end
      end

      it "opens a connection again when a setting changed while the request before it was sent" do
        stub_request(:get, https_uri.to_s).to_return { (connection.read_timeout = 1) && {status: 200} }.then
          .to_return(status: 200)
        2.times { get }

        expect(built.size).to eq(2)
      end

      it "closes the connection kept open when a setting changed while its request was sent" do
        stub_request(:get, https_uri.to_s).to_return { (connection.read_timeout = 1) && {status: 200} }.then
          .to_return(status: 200)
        2.times { get }

        expect(built.first).not_to be_started
      end

      it "keeps the connection open when the keep-alive timeout changed to zero while its request was sent" do
        stub_request(:get, https_uri.to_s).to_return { (connection.keep_alive_timeout = 0) && {status: 200} }
        get

        expect(built.first).to be_started
      end

      it "closes the connection it kept open when a setting has changed" do
        get
        connection.read_timeout = 1
        get

        expect(built.first).not_to be_started
      end

      it "closes the connection of a request that failed" do
        stub_request(:get, http_uri.to_s).to_raise(Errno::ECONNRESET)
        get_ignoring_errors(http_uri)

        expect(built.first).not_to be_started
      end

      [RuntimeError, Interrupt].each do |error_class|
        it "closes the connection of a request interrupted by #{error_class}" do
          stub_request(:get, https_uri.to_s).to_raise(error_class)
          get_rescuing(error_class)

          expect(built.first).not_to be_started
        end
      end

      it "does not keep the connection of a request that failed" do
        stub_request(:get, https_uri.to_s).to_raise(Errno::ECONNRESET).then.to_return(status: 200)
        2.times { get_ignoring_errors }

        expect(built.size).to eq(2)
      end
    end
  end

  describe "#build_http_client" do
    def build_http_client(uri, connection: self.connection)
      connection.send(:build_http_client, uri)
    end

    it "leaves sending a request again to the retry handler" do
      expect(build_http_client(https_uri).max_retries).to eq(0)
    end

    it "returns a Net::HTTP client" do
      expect(build_http_client(https_uri)).to be_a(Net::HTTP)
    end

    it "hands the certificates to the client" do
      connection = described_class.new(ca_file: certificate_path("ca.pem"), client_cert: test_client_cert)
      http_client = build_http_client(https_uri, connection:)

      expect([http_client.ca_file, http_client.cert])
        .to eq([connection.ca_file, connection.client_cert])
    end

    it "hands no certificates to the client when none are configured" do
      expect(build_http_client(https_uri).ca_file).to be_nil
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

    it "applies the keep-alive timeout" do
      connection = described_class.new(keep_alive_timeout: 10)

      expect(build_http_client(https_uri, connection:).keep_alive_timeout).to eq(10)
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

      expect(build_http_client(https_uri, connection:).instance_variable_get(:@debug_output).output).to equal($stderr)
    end

    it "redacts credentials from the debug output" do
      connection = described_class.new(debug_output: $stderr)

      expect(build_http_client(https_uri, connection:).instance_variable_get(:@debug_output))
        .to be_an_instance_of(Gems::RedactedOutput)
    end

    it "does not set debug output by default" do
      expect(build_http_client(https_uri).instance_variable_get(:@debug_output)).to be_nil
    end

    context "without a proxy" do
      it "does not use a proxy" do
        expect(build_http_client(https_uri)).not_to be_proxy
      end

      it "does not set TLS for the proxy" do
        expect(build_http_client(https_uri).instance_variable_get(:@proxy_use_ssl)).to be_nil
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

      it "decodes the proxy user and password" do
        connection = described_class.new(proxy_url: "http://us%40er:p%40ss@proxy.example.com:8080")
        http_client = connection.send(:build_http_client, https_uri)

        expect([http_client.proxy_user, http_client.proxy_pass]).to eq(["us@er", "p@ss"])
      end

      it "does not use TLS for an http proxy" do
        expect(build_http_client(https_uri).instance_variable_get(:@proxy_use_ssl)).to be(false)
      end

      it "uses TLS for an https proxy" do
        connection = described_class.new(proxy_url: "https://proxy.example.com:8443")

        expect(build_http_client(https_uri, connection:).instance_variable_get(:@proxy_use_ssl)).to be(true)
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

      it "decodes the proxy user and password" do
        with_env("https_proxy" => "http://env%40user:env%40pass@env.example.com:9999") do
          http_client = build_http_client(https_uri)

          expect([http_client.proxy_user, http_client.proxy_pass]).to eq(["env@user", "env@pass"])
        end
      end

      it "uses TLS for an https proxy" do
        with_env("https_proxy" => "https://env.example.com:9999") do
          expect(build_http_client(https_uri).instance_variable_get(:@proxy_use_ssl)).to be(true)
        end
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
