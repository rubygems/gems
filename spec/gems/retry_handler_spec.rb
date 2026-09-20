RSpec.describe Gems::RetryHandler do
  subject(:handler) { described_class.new(max_retries: 2) }

  let(:request) { Net::HTTP::Get.new(URI("#{TEST_HOST}/api/v1/gems/rails.json")) }
  let(:post_request) { Net::HTTP::Post.new(URI("#{TEST_HOST}/api/v1/gems")) }
  let(:success) { build_response(Net::HTTPOK, "200", "OK", "body") }

  def rate_limited(retry_after: nil)
    response = build_response(Net::HTTPTooManyRequests, "429", "Too Many Requests", "throttled")
    response["Retry-After"] = retry_after unless retry_after.nil?
    response
  end

  def unavailable
    build_response(Net::HTTPServiceUnavailable, "503", "Service Unavailable", "down")
  end

  # Send the given responses in turn, recording the seconds waited between them
  def handle(handler, responses, request: self.request)
    waited = []
    allow(handler).to receive(:sleep) { |seconds| waited << seconds }
    remaining = responses.dup
    response = handler.handle(request:) { remaining.shift }
    [response, waited]
  end

  describe "::DEFAULT_MAX_RETRIES" do
    it "does not retry" do
      expect(described_class::DEFAULT_MAX_RETRIES).to eq(0)
    end
  end

  describe "::DEFAULT_MAX_RETRY_DELAY" do
    it "is a minute" do
      expect(described_class::DEFAULT_MAX_RETRY_DELAY).to eq(60)
    end
  end

  describe "#initialize" do
    it "defaults to the default maximums" do
      handler = described_class.new

      expect([handler.max_retries, handler.max_retry_delay])
        .to eq([described_class::DEFAULT_MAX_RETRIES, described_class::DEFAULT_MAX_RETRY_DELAY])
    end
  end

  describe "#handle" do
    it "returns a successful response without sending the request again" do
      response, waited = handle(handler, [success])

      expect([response, waited]).to eq([success, []])
    end

    it "returns a response that is not retried" do
      not_found = build_response(Net::HTTPNotFound, "404", "Not Found", "missing")
      response, = handle(handler, [not_found])

      expect(response).to equal(not_found)
    end

    it "sends the request again after a 429" do
      response, = handle(handler, [rate_limited, success])

      expect(response).to equal(success)
    end

    it "sends the request again after a 503" do
      response, = handle(handler, [unavailable, success])

      expect(response).to equal(success)
    end

    it "waits the seconds the Retry-After header asks for" do
      _, waited = handle(handler, [rate_limited(retry_after: "5"), success])

      expect(waited).to eq([5])
    end

    it "waits the seconds until the HTTP date the Retry-After header asks for" do
      _, waited = handle(handler, [rate_limited(retry_after: (Time.now + 4).httpdate), success])

      expect(waited.first).to be_between(1, 5)
    end

    it "doubles the wait without a Retry-After header" do
      _, waited = handle(handler, [rate_limited, rate_limited, success])

      expect(waited).to eq([1, 2])
    end

    it "gives up after the maximum number of retries" do
      last = rate_limited
      response, waited = handle(handler, [rate_limited, rate_limited, last])

      expect([response, waited]).to eq([last, [1, 2]])
    end

    it "does not retry when the maximum is zero" do
      response, waited = handle(described_class.new, [rate_limited, success])

      expect([response.code, waited]).to eq(["429", []])
    end

    it "does not retry a request that is not idempotent" do
      response, waited = handle(handler, [rate_limited, success], request: post_request)

      expect([response.code, waited]).to eq(["429", []])
    end

    it "does not wait longer than the maximum retry delay" do
      response, waited = handle(handler, [rate_limited(retry_after: "61"), success])

      expect([response.code, waited]).to eq(["429", []])
    end

    it "waits a delay equal to the maximum retry delay" do
      _, waited = handle(handler, [rate_limited(retry_after: "60"), success])

      expect(waited).to eq([60])
    end
  end
end
