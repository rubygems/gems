# frozen_string_literal: true

RSpec.describe Gems::Pagination do
  let(:paginated) do
    Class.new do
      include Gems::Pagination

      attr_reader :requested

      def initialize(pages)
        @pages = pages
        @requested = []
      end

      def each_result(&block)
        each_page(block) { |page| request(page) }
      end

      private

      def request(page)
        @requested << page
        @pages.fetch(page, [])
      end
    end
  end

  let(:pages) { {1 => %w[a b], 2 => %w[c]} }
  let(:subject_with_pages) { paginated.new(pages) }

  it "returns an enumerator without a block" do
    expect(subject_with_pages.each_result).to be_a(Enumerator)
  end

  it "enumerates the results of every page in order" do
    expect(subject_with_pages.each_result.to_a).to eq(%w[a b c])
  end

  it "stops at a page shorter than the first, without requesting the page after it" do
    subject_with_pages.each_result.to_a

    expect(subject_with_pages.requested).to eq([1, 2])
  end

  it "stops at the first empty page when every page before it is full" do
    full = paginated.new({1 => %w[a b], 2 => %w[c d]})

    expect([full.each_result.to_a, full.requested]).to eq([%w[a b c d], [1, 2, 3]])
  end

  it "requests the page after a first page of any size" do
    single = paginated.new({1 => %w[a]})

    expect([single.each_result.to_a, single.requested]).to eq([%w[a], [1, 2]])
  end

  it "walks pages of the size the first page has, rather than a fixed size" do
    pages = {1 => %w[a b c], 2 => %w[d e f], 3 => %w[g h i], 4 => %w[j]}
    walk = paginated.new(pages)

    expect([walk.each_result.to_a, walk.requested]).to eq([%w[a b c d e f g h i j], [1, 2, 3, 4]])
  end

  it "stops at a page that is the same as the page before it, keeping the results already enumerated" do
    repeating = paginated.new({1 => %w[a b], 2 => %w[a b], 3 => %w[a b]})

    expect([repeating.each_result.to_a, repeating.requested]).to eq([%w[a b], [1, 2]])
  end

  it "does not stop at a page that is the same as one before the page before it" do
    pages = {1 => %w[a b], 2 => %w[c d], 3 => %w[a b], 4 => %w[e]}
    walk = paginated.new(pages)

    expect(walk.each_result.to_a).to eq(%w[a b c d a b e])
  end

  it "does not stop at a page longer than the first" do
    pages = {1 => %w[a], 2 => %w[b c], 3 => %w[d]}
    walk = paginated.new(pages)

    expect(walk.each_result.to_a).to eq(%w[a b c d])
  end

  it "requests the first page only once the enumeration starts" do
    subject_with_pages.each_result

    expect(subject_with_pages.requested).to be_empty
  end

  it "does not request a page the enumeration does not reach" do
    subject_with_pages.each_result.first(2)

    expect(subject_with_pages.requested).to eq([1])
  end

  it "yields nothing when the first page is empty" do
    empty = paginated.new({})

    expect([empty.each_result.to_a, empty.requested]).to eq([[], [1]])
  end

  it "calls a block with each result" do
    results = []
    subject_with_pages.each_result { |result| results << result }

    expect(results).to eq(%w[a b c])
  end

  it "returns the enumerator when a block is given" do
    expect(subject_with_pages.each_result { nil }).to be_a(Enumerator)
  end

  it "enumerates again from the first page" do
    enumerator = subject_with_pages.each_result
    2.times { enumerator.to_a }

    expect(subject_with_pages.requested).to eq([1, 2, 1, 2])
  end
end
