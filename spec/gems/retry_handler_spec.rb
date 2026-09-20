# frozen_string_literal: true

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

  def bad_gateway
    build_response(Net::HTTPBadGateway, "502", "Bad Gateway", "bad gateway")
  end

  def gateway_timeout
    build_response(Net::HTTPGatewayTimeout, "504", "Gateway Timeout", "gateway timeout")
  end

  def network_error
    Gems::NetworkError.new("Network error: connection reset")
  end

  # Send the given responses in turn, raising the ones that are errors, and recording the seconds waited between them
  def handle(handler, responses, request: self.request)
    waited = []
    allow(handler).to receive(:sleep) { |seconds| waited << seconds }
    remaining = responses.dup
    response = handler.handle(request:) do
      answer = remaining.shift
      answer.is_a?(Exception) ? raise(answer) : answer
    end
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

    it "sends the request again after a 502" do
      response, = handle(handler, [bad_gateway, success])

      expect(response).to equal(success)
    end

    it "sends the request again after a 504" do
      response, = handle(handler, [gateway_timeout, success])

      expect(response).to equal(success)
    end

    it "does not send the request again after a 500" do
      internal = build_response(Net::HTTPInternalServerError, "500", "Internal Server Error", "boom")
      response, waited = handle(handler, [internal, success])

      expect([response, waited]).to eq([internal, []])
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

    it "does not wait longer than the maximum retry delay the response asks for" do
      response, waited = handle(handler, [rate_limited(retry_after: "61"), success])

      expect([response.code, waited]).to eq(["429", []])
    end

    it "waits a delay equal to the maximum retry delay" do
      _, waited = handle(handler, [rate_limited(retry_after: "60"), success])

      expect(waited).to eq([60])
    end

    it "shortens a doubling wait to the maximum retry delay" do
      handler = described_class.new(max_retries: 3, max_retry_delay: 3)
      _, waited = handle(handler, [rate_limited, rate_limited, rate_limited, success])

      expect(waited).to eq([1, 2, 3])
    end

    it "sends the request again as many times as asked once the wait reaches the maximum retry delay" do
      handler = described_class.new(max_retries: 5, max_retry_delay: 2)
      response, waited = handle(handler, [*Array.new(5) { rate_limited }, success])

      expect([response, waited]).to eq([success, [1, 2, 2, 2, 2]])
    end

    context "when the request is lost to the network" do
      it "sends the request again" do
        response, = handle(handler, [network_error, success])

        expect(response).to equal(success)
      end

      it "doubles the wait between attempts" do
        _, waited = handle(handler, [network_error, network_error, success])

        expect(waited).to eq([1, 2])
      end

      it "raises the error after the maximum number of retries" do
        last = network_error

        expect { handle(handler, [network_error, network_error, last]) }.to raise_error(last)
      end

      it "raises the error when the maximum is zero" do
        expect { handle(described_class.new, [network_error, success]) }
          .to raise_error(Gems::NetworkError, "Network error: connection reset")
      end

      it "raises the error for a request that is not idempotent" do
        expect { handle(handler, [network_error, success], request: post_request) }.to raise_error(Gems::NetworkError)
      end

      it "shortens the wait to the maximum retry delay" do
        handler = described_class.new(max_retries: 3, max_retry_delay: 3)
        _, waited = handle(handler, [network_error, network_error, network_error, success])

        expect(waited).to eq([1, 2, 3])
      end

      it "waits a delay equal to the maximum retry delay" do
        handler = described_class.new(max_retries: 2, max_retry_delay: 1)
        _, waited = handle(handler, [network_error, success])

        expect(waited).to eq([1])
      end
    end
  end
end
