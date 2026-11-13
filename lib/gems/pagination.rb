# frozen_string_literal: true

module Gems
  # Walks the pages of the endpoints that answer one page at a time, mixed into the API endpoints
  #
  # The endpoints number their pages from one, so a page is requested only when the results of the page before it
  # have been enumerated. The walk ends with the last page there is, which is the first page that is:
  #
  # * empty, as the endpoints answer once there are no more results;
  # * shorter than the first page, since a page is only cut short when it is the last; or
  # * the same as the page before it, when a host ignores the page it is asked for.
  #
  # The size of a full page is taken from the first page rather than fixed, since a host other than RubyGems.org
  # may serve pages of another size: a walk of such a host neither stops after its first page nor runs past its
  # last. The walk stops rather than raising, so a caller keeps every result it was given.
  #
  # @api private
  module Pagination
    # The page the endpoints number their first page with
    FIRST_PAGE = 1
    private_constant :FIRST_PAGE

    private

    # Enumerate the results of a paginated endpoint
    #
    # The enumerator is given the block, which enumerates every page when there is one, and is returned either way,
    # since `Enumerator#each` without a block enumerates nothing and answers with the enumerator itself. The
    # signature of `Enumerator#each` has no overload for a block that may be absent, which is what the block a
    # method was called without is, so passing one is checked past.
    #
    # @api private
    # @param block [Proc, nil] the block to call with each result, or nil to only return the enumerator
    # @yield [page] the page to request
    # @yieldreturn [Array] the results of that page, empty once there are no more
    # @return [Enumerator] the results, which requests each page as it is reached
    def each_page(block)
      enumerator = Enumerator.new { |yielder| walk_pages(yielder) { |page| yield(page) } }
      enumerator.each(&block) # steep:ignore BlockTypeMismatch
      enumerator
    end

    # Yield the results of each page to the yielder, until the last page there is
    #
    # @api private
    # @param yielder [Enumerator::Yielder] the yielder of the enumerator the results are enumerated by
    # @yield [page] the page to request
    # @yieldreturn [Array] the results of that page
    # @return [void]
    def walk_pages(yielder)
      page = FIRST_PAGE
      full = (results = yield(page)).size
      until results.empty?
        results.each { |result| yielder << result }
        break if results.size < full

        previous = results
        break if (results = yield(page += 1)).eql?(previous)
      end
    end
  end
end
