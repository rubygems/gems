# frozen_string_literal: true

RSpec.describe Gems::RetryHandler do
  subject(:handler) { described_class.new(max_retries: 2, random: steady) }

  # A source of randomness that jitters nothing, so that the waits between attempts are exactly the backoff
  let(:steady) { instance_double(Random, rand: 0.0) }

  # A source of randomness that jitters as far as the backoff allows, which is half of the wait
  let(:jittery) { instance_double(Random, rand: 1.0) }

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
  def handle(handler, responses, retry_refused: true, retry_unanswered: true, retry_lost: true, **options)
    waited = []
    allow(handler).to receive(:sleep) { |seconds| waited << seconds }
    remaining = responses.dup
    response = handler.handle(retry_refused:, retry_unanswered:, retry_lost:, **options) do
      answer = remaining.shift
      answer.is_a?(Exception) ? raise(answer) : answer
    end
    [response, waited]
  end

  describe "::DEFAULT_MAX_RETRIES" do
    it "sends a request again twice" do
      expect(described_class::DEFAULT_MAX_RETRIES).to eq(2)
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

    it "defaults to Random for the jitter of the backoff" do
      expect(described_class.new.random).to equal(Random)
    end
  end

  describe "#max_retries=" do
    it "assigns a number of retries" do
      handler.max_retries = 3

      expect(handler.max_retries).to eq(3)
    end

    it "raises for a negative number of retries" do
      expect { handler.max_retries = -1 }.to raise_error(ArgumentError, "Invalid max_retries: -1")
    end

    it "raises for a number of retries that is not whole" do
      expect { handler.max_retries = 1.5 }.to raise_error(ArgumentError, "Invalid max_retries: 1.5")
    end

    it "leaves the maximum as it was after a value it refuses" do
      handler.max_retries = 3
      handler.max_retries = -1
    rescue ArgumentError
      expect(handler.max_retries).to eq(3)
    end

    it "refuses the maximum the handler is built with" do
      expect { described_class.new(max_retries: -1) }.to raise_error(ArgumentError, "Invalid max_retries: -1")
    end
  end

  describe "#max_retry_delay=" do
    it "assigns a number of seconds" do
      handler.max_retry_delay = 0.5

      expect(handler.max_retry_delay).to eq(0.5)
    end

    it "raises for a negative number of seconds" do
      expect { handler.max_retry_delay = -1 }.to raise_error(ArgumentError, "Invalid max_retry_delay: -1")
    end

    it "raises for a value that is not a number" do
      expect { handler.max_retry_delay = "30" }.to raise_error(ArgumentError, "Invalid max_retry_delay: \"30\"")
    end

    it "leaves the maximum as it was after a value it refuses" do
      handler.max_retry_delay = 30
      handler.max_retry_delay = -1
    rescue ArgumentError
      expect(handler.max_retry_delay).to eq(30)
    end

    it "refuses the maximum the handler is built with" do
      expect { described_class.new(max_retry_delay: -1) }.to raise_error(ArgumentError, "Invalid max_retry_delay: -1")
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

    it "jitters the doubling wait down by as much as half" do
      handler = described_class.new(max_retries: 2, random: jittery)
      _, waited = handle(handler, [rate_limited, rate_limited, success])

      expect(waited).to eq([0.5, 1])
    end

    it "jitters the wait after a network error too" do
      handler = described_class.new(max_retries: 2, random: jittery)
      _, waited = handle(handler, [network_error, network_error, success])

      expect(waited).to eq([0.5, 1])
    end

    it "waits between half of the doubling wait and all of it" do
      handler = described_class.new(max_retries: 5, random: Random.new(1_649))
      _, waited = handle(handler, [*Array.new(5) { rate_limited }, success])
      within_bounds = waited.each_with_index.map { |seconds, retries| (2**retries / 2.0..2**retries).cover?(seconds) }

      expect(within_bounds).to eq([true] * 5)
    end

    it "does not jitter the wait the Retry-After header asks for" do
      handler = described_class.new(max_retries: 2, random: jittery)
      _, waited = handle(handler, [rate_limited(retry_after: "5"), success])

      expect(waited).to eq([5])
    end

    it "gives up after the maximum number of retries" do
      last = rate_limited
      response, waited = handle(handler, [rate_limited, rate_limited, last])

      expect([response, waited]).to eq([last, [1, 2]])
    end

    it "does not retry when the maximum is zero" do
      response, waited = handle(described_class.new(max_retries: 0), [rate_limited, success])

      expect([response.code, waited]).to eq(["429", []])
    end

    it "does not send a request again after a 502 when the caller says it may not be answered twice" do
      response, waited = handle(handler, [bad_gateway, success], retry_unanswered: false)

      expect([response.code, waited]).to eq(["502", []])
    end

    it "does not send a request again after a 504 when the caller says it may not be answered twice" do
      response, waited = handle(handler, [gateway_timeout, success], retry_unanswered: false)

      expect([response.code, waited]).to eq(["504", []])
    end

    it "sends a request the server turned away again although it may not be answered twice" do
      response, = handle(handler, [rate_limited, success], retry_unanswered: false)

      expect(response).to equal(success)
    end

    it "sends a request again after a 502 when only that is allowed" do
      response, = handle(handler, [bad_gateway, success], retry_refused: false)

      expect(response).to equal(success)
    end

    it "does not send a request the server turned away again when only a 502 is allowed" do
      response, waited = handle(handler, [rate_limited, success], retry_refused: false)

      expect([response.code, waited]).to eq(["429", []])
    end

    it "does not send a request again when the caller allows neither" do
      response, waited = handle(handler, [rate_limited, success], retry_refused: false, retry_unanswered: false,
        retry_lost: false)

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
      handler = described_class.new(max_retries: 3, max_retry_delay: 3, random: steady)
      _, waited = handle(handler, [rate_limited, rate_limited, rate_limited, success])

      expect(waited).to eq([1, 2, 3])
    end

    it "sends the request again as many times as asked once the wait reaches the maximum retry delay" do
      handler = described_class.new(max_retries: 5, max_retry_delay: 2, random: steady)
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
        expect { handle(described_class.new(max_retries: 0), [network_error, success]) }
          .to raise_error(Gems::NetworkError, "Network error: connection reset")
      end

      it "raises the error when the caller allows neither" do
        expect { handle(handler, [network_error, success], retry_refused: false, retry_unanswered: false, retry_lost: false) }
          .to raise_error(Gems::NetworkError)
      end

      it "shortens the wait to the maximum retry delay" do
        handler = described_class.new(max_retries: 3, max_retry_delay: 3, random: steady)
        _, waited = handle(handler, [network_error, network_error, network_error, success])

        expect(waited).to eq([1, 2, 3])
      end

      it "waits a delay equal to the maximum retry delay" do
        handler = described_class.new(max_retries: 2, max_retry_delay: 1, random: steady)
        _, waited = handle(handler, [network_error, success])

        expect(waited).to eq([1])
      end
    end

    context "when the caller says what the request is safe to be sent again for" do
      it "sends a request again when only a refusal is allowed and the server turns it away" do
        response, waited = handle(handler, [rate_limited, success], retry_refused: true, retry_lost: false)

        expect([response, waited]).to eq([success, [1]])
      end

      it "raises when only a refusal is allowed and the request is lost to the network" do
        expect { handle(handler, [network_error, success], retry_refused: true, retry_lost: false) }
          .to raise_error(Gems::NetworkError)
      end

      it "sends a request again when only a loss is allowed and it is lost to the network" do
        response, = handle(handler, [network_error, success], retry_refused: false, retry_lost: true)

        expect(response).to equal(success)
      end

      it "leaves a request the server turned away as it is when a refusal is not allowed" do
        response, waited = handle(handler, [rate_limited, success], retry_refused: false)

        expect([response.code, waited]).to eq(["429", []])
      end

      it "raises for a request lost to the network when a loss is not allowed" do
        expect { handle(handler, [network_error, success], retry_lost: false) }.to raise_error(Gems::NetworkError)
      end
    end
  end
end
