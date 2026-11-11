# frozen_string_literal: true

require_relative "errors/too_many_pages"
require_relative "settings"

module Gems
  # Walks the pages of the endpoints that answer one page at a time, mixed into the API endpoints
  #
  # The endpoints number their pages from one and answer with an empty list once there are no more, so a page is
  # requested only when the results of the page before it have been enumerated, and the walk stops at the first
  # empty page.
  #
  # The page the walk stops at is the host's to answer, so the walk is also given a maximum of its own, the
  # `max_pages` the module declares and the client an endpoint is mixed into sets: a page past the maximum is
  # not enumerated, and one that answers with results raises {TooManyPages}, as a redirect past the
  # `max_redirects` of a client raises {TooManyRedirects}, since a host that answers every page with results —
  # one that ignores the page a walk asks for — would keep a walk going for as long as the caller keeps
  # enumerating. The page past the maximum is still asked whether it has results, since the walk stops at the
  # first empty page and only the host can answer which page that is.
  #
  # @api private
  module Pagination
    # The page the endpoints number their first page with
    FIRST_PAGE = 1
    # Default maximum number of pages to enumerate
    DEFAULT_MAX_PAGES = 1000
    private_constant :FIRST_PAGE

    include Settings

    # @!method max_pages
    #   The maximum number of pages a page-at-a-time endpoint enumerates
    #
    #   @api public
    #   @return [Integer] the maximum number of pages to enumerate
    #   @example Get the maximum pages
    #     client.max_pages
    # @!method max_pages=(max_pages)
    #   Set the maximum number of pages a page-at-a-time endpoint enumerates
    #
    #   @api public
    #   @param max_pages [Integer] the maximum number of pages to enumerate
    #   @return [void]
    #   @raise [ArgumentError] if it is not a whole number of times, in which case the maximum is left as it was
    #   @example Set the maximum pages
    #     client.max_pages = 100
    count_setting :max_pages

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
    # @raise [TooManyPages] if a page past the `max_pages` of the client answers with results
    def each_page(block)
      enumerator = Enumerator.new do |yielder|
        page = FIRST_PAGE
        until (results = yield(page)).empty?
          raise TooManyPages, "Too many pages" if page > max_pages
          results.each { |result| yielder << result }
          page += 1
        end
      end
      enumerator.each(&block) # steep:ignore BlockTypeMismatch
      enumerator
    end
  end
end
