RSpec.describe Gems::ConnectionPool do
  subject(:pool) { described_class.new }

  let(:http_client) { instance_double(Net::HTTP, started?: true, finish: nil) }

  let(:opened) { instance_double(Net::HTTP, start: nil, started?: true, finish: nil) }

  def key
    ["https", "rubygems.org", 443]
  end

  def settings
    [60, 60, 60, 2, nil, nil]
  end

  def request
    Net::HTTP::Get.new(URI("https://rubygems.org/path"))
  end

  def post
    Net::HTTP::Post.new(URI("https://rubygems.org/path"))
  end

  # Spy on the lock the pool holds while it reads and writes the connections it keeps
  def spy_on_lock
    pool.instance_variable_get(:@mutex).tap { |mutex| allow(mutex).to receive(:synchronize).and_call_original }
  end

  describe "#checkout" do
    it "opens a connection when none is kept for the host" do
      expect(pool.checkout(request:, settings:, keep_alive_timeout: 2) { opened }).to equal(opened)
    end

    it "opens the connection it is given" do
      pool.checkout(request:, settings:, keep_alive_timeout: 2) { opened }

      expect(opened).to have_received(:start)
    end

    it "returns the connection kept for the host" do
      pool.store(key, http_client, settings)

      expect(pool.checkout(request:, settings:, keep_alive_timeout: 2) { opened }).to equal(http_client)
    end

    it "does not open the connection kept for the host again" do
      pool.store(key, http_client, settings)
      pool.checkout(request:, settings:, keep_alive_timeout: 2) { opened }

      expect(opened).not_to have_received(:start)
    end

    it "opens a connection when the keep-alive timeout is zero" do
      pool.store(key, http_client, settings)

      expect(pool.checkout(request:, settings:, keep_alive_timeout: 0) { opened }).to equal(opened)
    end

    it "opens a connection for a request that is not idempotent" do
      pool.store(key, http_client, settings)

      expect(pool.checkout(request: post, settings:, keep_alive_timeout: 2) { opened }).to equal(opened)
    end

    it "opens a connection when the one kept was opened with other settings" do
      pool.store(key, http_client, [1, 60, 60, 2, nil, nil])

      expect(pool.checkout(request:, settings:, keep_alive_timeout: 2) { opened }).to equal(opened)
    end
  end

  describe "#checkin" do
    it "keeps the connection for the host" do
      pool.checkin(request:, http_client:, settings:, keep_alive_timeout: 2)

      expect(pool.take(key, settings)).to equal(http_client)
    end

    it "does not close the connection it keeps" do
      pool.checkin(request:, http_client:, settings:, keep_alive_timeout: 2)

      expect(http_client).not_to have_received(:finish)
    end

    it "closes a request that is not idempotent" do
      pool.checkin(request: post, http_client:, settings:, keep_alive_timeout: 2)

      expect(http_client).to have_received(:finish)
    end

    it "keeps nothing for a request that is not idempotent" do
      pool.checkin(request: post, http_client:, settings:, keep_alive_timeout: 2)

      expect(pool.take(key, settings)).to be_nil
    end

    it "closes the connection when the keep-alive timeout is zero" do
      pool.checkin(request:, http_client:, settings:, keep_alive_timeout: 0)

      expect(http_client).to have_received(:finish)
    end
  end

  describe "#discard" do
    it "closes an open connection" do
      pool.discard(http_client)

      expect(http_client).to have_received(:finish)
    end

    it "does nothing when no connection was opened" do
      expect(pool.discard(nil)).to be_nil
    end

    it "does nothing for a connection that is not open" do
      expect(pool.discard(instance_double(Net::HTTP, started?: false))).to be_nil
    end
  end

  describe "#delete" do
    it "returns the connection kept for the key" do
      pool.store(key, http_client, settings)

      expect(pool.send(:delete, key)).to equal(http_client)
    end

    it "returns nothing when none is kept for the key" do
      expect(pool.send(:delete, key)).to be_nil
    end

    it "takes the connection under the lock" do
      mutex = spy_on_lock
      pool.send(:delete, key)

      expect(mutex).to have_received(:synchronize)
    end

    it "returns the connection only once" do
      pool.store(key, http_client, settings)
      pool.send(:delete, key)

      expect(pool.send(:delete, key)).to be_nil
    end
  end

  describe "#take" do
    it "returns nothing when none is kept for the key" do
      expect(pool.take(key, settings)).to be_nil
    end

    it "takes the connection under the lock" do
      mutex = spy_on_lock
      pool.take(key, settings)

      expect(mutex).to have_received(:synchronize)
    end

    it "returns the connection kept for the key" do
      pool.store(key, http_client, settings)

      expect(pool.take(key, settings)).to equal(http_client)
    end

    it "returns nothing for another key" do
      pool.store(key, http_client, settings)

      expect(pool.take(["http", "rubygems.org", 80], settings)).to be_nil
    end

    it "returns the connection only once" do
      pool.store(key, http_client, settings)
      pool.take(key, settings)

      expect(pool.take(key, settings)).to be_nil
    end

    it "returns nothing for a connection opened with other settings" do
      pool.store(key, instance_double(Net::HTTP, started?: true, finish: :closed), settings)

      expect(pool.take(key, [1, 60, 60, 2, nil, nil])).to be_nil
    end

    it "closes a connection opened with other settings" do
      pool.store(key, http_client, settings)
      pool.take(key, [1, 60, 60, 2, nil, nil])

      expect(http_client).to have_received(:finish)
    end
  end

  describe "#store" do
    it "keeps the connection" do
      expect(pool.store(key, http_client, settings)).to be(true)
    end

    it "does not close the connection it keeps" do
      pool.store(key, http_client, settings)

      expect(http_client).not_to have_received(:finish)
    end

    it "keeps the connection under the lock" do
      mutex = spy_on_lock
      pool.store(key, http_client, settings)

      expect(mutex).to have_received(:synchronize)
    end

    it "does not keep a second connection for the same key" do
      pool.store(key, http_client, settings)

      expect(pool.store(key, instance_double(Net::HTTP, started?: false), settings)).to be(false)
    end

    it "closes a connection it does not keep" do
      other = instance_double(Net::HTTP, started?: true, finish: nil)
      pool.store(key, http_client, settings)
      pool.store(key, other, settings)

      expect(other).to have_received(:finish)
    end

    it "keeps the first connection when it does not keep a second" do
      pool.store(key, http_client, settings)
      pool.store(key, instance_double(Net::HTTP, started?: true, finish: nil), settings)

      expect(pool.take(key, settings)).to equal(http_client)
    end

    it "keeps a connection for each key" do
      other = instance_double(Net::HTTP, started?: false)
      pool.store(key, http_client, settings)
      pool.store(["http", "rubygems.org", 80], other, settings)

      expect(pool.take(["http", "rubygems.org", 80], settings)).to equal(other)
    end

    it "does not close a connection that is not open" do
      closed = instance_double(Net::HTTP, started?: false)
      pool.store(key, http_client, settings)

      expect(pool.store(key, closed, settings)).to be(false)
    end
  end

  describe "#close" do
    it "returns the pool" do
      expect(pool.close).to equal(pool)
    end

    it "closes the connections it keeps" do
      pool.store(key, http_client, settings)
      pool.close

      expect(http_client).to have_received(:finish)
    end

    it "keeps no connection afterwards" do
      pool.store(key, http_client, settings)
      pool.close

      expect(pool.take(key, settings)).to be_nil
    end

    it "closes the connection kept for each key" do
      other = instance_double(Net::HTTP, started?: true, finish: nil)
      pool.store(key, http_client, settings)
      pool.store(["http", "rubygems.org", 80], other, settings)
      pool.close

      expect(other).to have_received(:finish)
    end

    it "does not close a connection that is not open" do
      closed = instance_double(Net::HTTP, started?: false)
      pool.store(key, closed, settings)

      expect(pool.close).to equal(pool)
    end
  end
end
