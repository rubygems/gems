# frozen_string_literal: true

RSpec.describe Gems::RedactedOutput do
  subject(:redacted_output) { described_class.new(io) }

  let(:io) { StringIO.new }

  # The lines Net::HTTP writes for a body sent in two chunks, with an API key split between them
  let(:chunked_body) do
    [%(-> "1f\\r\\n"\n), "reading 31 bytes...\n", %(-> "{\\"rubygems_api_key\\":\\"rubygems_70"\n), "read 31 bytes\n",
      "reading 2 bytes...\n", %(-> "\\r\\n"\n), "read 2 bytes\n", %(-> "a\\r\\n"\n), "reading 10 bytes...\n",
      %(-> "1243f2\\"}"\n), "read 10 bytes\n", "reading 2 bytes...\n", %(-> "\\r\\n"\n), "read 2 bytes\n",
      %(-> "0\\r\\n"\n), %(-> "\\r\\n"\n), "Conn keep-alive\n"]
  end

  # The same lines as they are written, with the body joined where its first part was read and the key redacted
  let(:chunked_output) do
    [%(-> "1f\\r\\n"\n), "reading 31 bytes...\n", %(-> "{\\"rubygems_api_key\\":\\"[REDACTED]\\"}"\n), "read 31 bytes\n",
      "reading 2 bytes...\n", %(-> "\\r\\n"\n), "read 2 bytes\n", %(-> "a\\r\\n"\n), "reading 10 bytes...\n",
      "read 10 bytes\n", "reading 2 bytes...\n", %(-> "\\r\\n"\n), "read 2 bytes\n", %(-> "0\\r\\n"\n),
      %(-> "\\r\\n"\n), "Conn keep-alive\n"].join
  end

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

    it "redacts the one-time passcode the status of a WebAuthn verification carries" do
      redacted_output << %(-> "{\\"status\\":\\"success\\",\\"code\\":\\"123456\\"}")

      expect(io.string).to eq(%(-> "{\\"status\\":\\"success\\",\\"code\\":\\"[REDACTED]\\"}"))
    end

    it "redacts the API key of a response body read in two parts" do
      ["reading 64 bytes...\n", %(-> "{\\"rubygems_api_key\\":\\"rubygems_70"\n), %(-> "1243f2\\"}"\n), "read 64 bytes\n",
        "Conn keep-alive\n"].each { |string| redacted_output << string }

      expect(io.string)
        .to eq(%(reading 64 bytes...\n-> "{\\"rubygems_api_key\\":\\"[REDACTED]\\"}"\nread 64 bytes\nConn keep-alive\n))
    end

    it "joins the parts of a body read to the end of the connection" do
      ["reading all...\n", %(-> "one"\n), %(-> "two"\n), "read 6 bytes\n", "Conn close\n"]
        .each { |string| redacted_output << string }

      expect(io.string).to eq(%(reading all...\n-> "onetwo"\nread 6 bytes\nConn close\n))
    end

    it "writes nothing for a body read in no parts" do
      ["reading 0 bytes...\n", "read 0 bytes\n", "Conn close\n"].each { |string| redacted_output << string }

      expect(io.string).to eq("reading 0 bytes...\nread 0 bytes\nConn close\n")
    end

    it "holds the lines of a body until the response is done" do
      ["reading 3 bytes...\n", %(-> "one"\n), "read 3 bytes\n"].each { |string| redacted_output << string }

      expect(io.string).to eq("")
    end

    it "redacts the API key of a body sent in chunks, split between two of them" do
      chunked_body.each { |string| redacted_output << string }

      expect(io.string).to eq(chunked_output)
    end

    it "does not join the lines of a response that are not a body" do
      [%(-> "HTTP/1.1 200 OK\\r\\n"\n), %(-> "Content-Length: 3\\r\\n"\n)].each { |string| redacted_output << string }

      expect(io.string).to eq(%(-> "HTTP/1.1 200 OK\\r\\n"\n-> "Content-Length: 3\\r\\n"\n))
    end

    it "writes the parts of a body read so far before whatever is written next" do
      ["reading 6 bytes...\n", %(-> "one"\n), "Conn close\n"].each { |string| redacted_output << string }

      expect(io.string).to eq(%(reading 6 bytes...\n-> "one"\nConn close\n))
    end

    it "does not join the lines read between the reads of a body to it" do
      ["reading 3 bytes...\n", %(-> "one"\n), "read 3 bytes\n", %(-> "HTTP/1.1 200 OK\\r\\n"\n), %(-> "two"\n),
        "Conn close\n"].each { |string| redacted_output << string }

      expect(io.string)
        .to eq(%(reading 3 bytes...\n-> "one"\nread 3 bytes\n-> "HTTP/1.1 200 OK\\r\\n"\n-> "two"\nConn close\n))
    end

    it "writes the lines of the next response as they come once a body is done" do
      ["reading 3 bytes...\n", %(-> "one"\n), "read 3 bytes\n", "Conn keep-alive\n", %(-> "two"\n)]
        .each { |string| redacted_output << string }

      expect(io.string).to eq(%(reading 3 bytes...\n-> "one"\nread 3 bytes\nConn keep-alive\n-> "two"\n))
    end

    it "does not redact a header that only looks like one, without the escaped newline" do
      redacted_output << '-> "X-Note: Authorization: not a header\\r\\n"'

      expect(io.string).to eq('-> "X-Note: Authorization: not a header\\r\\n"')
    end

    context "with the debug output of Net::HTTP" do
      let(:body) { %({"name":"ci-push","rubygems_api_key":"rubygems_701243f217cdf23b1370c7b66b65ca97"}) }
      let(:server) { TCPServer.new("127.0.0.1", 0) }

      around do |example|
        WebMock.allow_net_connect!
        example.run
      ensure
        WebMock.disable_net_connect!
        server.close
      end

      # Answer one request with the body, sent in two parts, so that it is read from the socket in two
      def serve_in_two_parts
        Thread.new do
          socket = server.accept
          nil until socket.gets == "\r\n"
          socket.write("HTTP/1.1 200 OK\r\nContent-Length: #{body.bytesize}\r\n\r\n#{body[0, 50]}")
          sleep 0.1
          socket.write(body[50..])
          socket.close
        end
      end

      # Answer one request with the body, sent in two chunks split in the middle of the API key
      def serve_in_two_chunks
        Thread.new do
          socket = server.accept
          nil until socket.gets == "\r\n"
          socket.write("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n")
          [body[0, 50], body[50..]].each { |chunk| socket.write("#{chunk.bytesize.to_s(16)}\r\n#{chunk}\r\n") && sleep(0.1) }
          socket.write("0\r\n\r\n")
          socket.close
        end
      end

      def get
        connection = Gems::Connection.new(debug_output: io, keep_alive_timeout: 0)
        connection.perform(request: Net::HTTP::Get.new(URI("http://127.0.0.1:#{server.addr[1]}/api/v1/api_key.json")))
      end

      it "writes no part of an API key a response body carries, when the body is read in two parts" do
        serve_in_two_parts
        get

        expect(io.string).not_to include("b1370c7b")
      end

      it "writes the body with the API key redacted" do
        serve_in_two_parts
        get

        expect(io.string).to include('\\"rubygems_api_key\\":\\"[REDACTED]\\"}')
      end

      it "writes no part of an API key a response body carries, when the body is sent in two chunks" do
        serve_in_two_chunks
        get

        expect(io.string).not_to include("b1370c7b")
      end

      it "writes the body sent in chunks with the API key redacted" do
        serve_in_two_chunks
        get

        expect(io.string).to include('\\"rubygems_api_key\\":\\"[REDACTED]\\"}')
      end
    end
  end
end
