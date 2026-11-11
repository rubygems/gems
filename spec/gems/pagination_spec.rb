# frozen_string_literal: true

RSpec.describe Gems::Pagination do
  let(:paginated) do
    Class.new do
      include Gems::Pagination

      attr_reader :requested

      def initialize(pages)
        @pages = pages
        @requested = []
        self.max_pages = Gems::Pagination::DEFAULT_MAX_PAGES
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

  it "stops at the first empty page" do
    subject_with_pages.each_result.to_a

    expect(subject_with_pages.requested).to eq([1, 2, 3])
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

    expect(empty.each_result.to_a).to be_empty
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

    expect(subject_with_pages.requested).to eq([1, 2, 3, 1, 2, 3])
  end

  it "yields the results of every page within the maximum" do
    many = paginated.new({1 => %w[a], 2 => %w[b], 3 => %w[c]})
    many.max_pages = 3

    expect(many.each_result.to_a).to eq(%w[a b c])
  end

  it "does not raise when the maximum is all the pages there are" do
    subject_with_pages.max_pages = 2

    expect(subject_with_pages.each_result.to_a).to eq(%w[a b c])
  end

  it "raises TooManyPages once a page past the maximum answers with results" do
    many = paginated.new({1 => %w[a], 2 => %w[b], 3 => %w[c]})
    many.max_pages = 2

    expect { many.each_result.to_a }.to raise_error(Gems::TooManyPages, "Too many pages")
  end

  it "requests the page past the maximum to ask whether it has results, and no page further" do
    many = paginated.new({1 => %w[a], 2 => %w[b], 3 => %w[c], 4 => %w[d]})
    many.max_pages = 2

    many.each_result.to_a
  rescue Gems::TooManyPages
    expect(many.requested).to eq([1, 2, 3])
  end
end
