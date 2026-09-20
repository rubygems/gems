# frozen_string_literal: true

module Gems
  # Walks the pages of the endpoints that answer one page at a time, mixed into the API endpoints
  #
  # The endpoints number their pages from one and answer with an empty list once there are no more, so a page is
  # requested only when the results of the page before it have been enumerated, and the walk stops at the first
  # empty page.
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
      enumerator = Enumerator.new do |yielder|
        page = FIRST_PAGE
        until (results = yield(page)).empty?
          results.each { |result| yielder << result }
          page += 1
        end
      end
      enumerator.each(&block) # steep:ignore BlockTypeMismatch
      enumerator
    end
  end
end
