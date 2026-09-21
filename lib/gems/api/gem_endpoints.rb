# frozen_string_literal: true

require "pathname"
require_relative "../identifiers"
require_relative "../json_parsing"
require_relative "../pagination"
require_relative "../path_escaping"
require_relative "../gem"
require_relative "../request_builder"

module Gems
  module API
    # The gem endpoints, which look up, search for, push, and yank gems
    # @api public
    module GemEndpoints
      include Identifiers
      include JSONParsing
      include Pagination
      include PathEscaping

      # The name a gem given as an IO with no path of its own is pushed under
      UNNAMED_GEM_FILENAME = "gem"
      private_constant :UNNAMED_GEM_FILENAME

      # Returns some basic information about the given gem
      #
      # @api public
      # @authenticated false
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version.
      # @return [Gem]
      # @example
      #   Gems.rubygem "rails"
      def rubygem(gem_name)
        Gem.new(parse_json(get("/api/v1/gems/#{escape(name_of(gem_name))}.json")))
      end

      # Returns an array of active gems that match the query
      #
      # @api public
      # @authenticated false
      # @param query [String] A term to search for.
      # @param page [Integer, nil] The page of results to return.
      # @return [Array<Gem>]
      # @example
      #   Gems.search "cucumber", page: 2
      def search(query, page: nil)
        Gem.list(parse_json(get("/api/v1/search.json", {query:, page:}.compact)))
      end

      # Enumerates the active gems that match the query, a page at a time
      #
      # A page is requested only when the gems of the page before it have been enumerated, and the enumeration ends
      # with the first empty page.
      #
      # @api public
      # @authenticated false
      # @param query [String] A term to search for.
      # @yield [gem] each gem, when a block is given
      # @return [Enumerator<Gem>] the gems
      # @example
      #   Gems.search_each("cucumber").first(100)
      def search_each(query, &block)
        each_page(block) { |page| search(query, page:) }
      end

      # Returns the names of gems matching the query, for populating a search box
      #
      # @api public
      # @authenticated false
      # @param query [String] The query to autocomplete.
      # @return [Array<String>]
      # @example
      #   Gems.autocomplete "nokogiri"
      def autocomplete(query)
        parse_json(get("/api/v1/search/autocomplete", {query:}))
      end

      # List all gems that you own, or that the given user owns
      #
      # The gems of a user given by handle are public; the gems of the account the credentials belong to, which is
      # what listing without a user asks for, are not.
      #
      # @api public
      # @authenticated true without a user, false with one
      # @param user_handle [String, Integer, Owner, Profile, nil] The handle or ID of a user, or an owner or profile.
      # @return [Array<Gem>]
      # @example
      #   Gems.owned_gems
      def owned_gems(user_handle = nil)
        path = if user_handle
          "/api/v1/owners/#{escape(slug_of(user_handle))}/gems.json"
        else
          "/api/v1/gems.json"
        end
        Gem.list(parse_json(get(path)))
      end

      # Submit a gem to RubyGems.org or another host
      #
      # @api public
      # @authenticated true
      # @param gem [String, Pathname, File] The path of a built gem, or the open file.
      # @param host [String, nil] A RubyGems compatible host to use (defaults to the client's host).
      # @param attestations [Array<String, Pathname, File>, nil] The paths of the attestations to push, or the open
      #   files, or `nil`.
      # @return [String] the message the endpoint answers with
      # @example
      #   Gems.push "pkg/gemcutter-0.2.1.gem"
      # @example
      #   Gems.push File.new("pkg/gemcutter-0.2.1.gem"), host: "https://gems.example.com"
      def push(gem, host: nil, attestations: nil)
        open_file(gem) do |file|
          body = attestations ? multipart_push_body(file, attestations) : file
          post("/api/v1/gems", body, host:)
        end
      end

      # Remove a gem from RubyGems.org's index
      #
      # @api public
      # @authenticated true
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version. A version stands in for the
      #   version argument too, so that yanking a version yanks that version.
      # @param version [String, Version, nil] The version of a gem (defaults to the version given as the gem, or to
      #   the latest version).
      # @param platform [String, nil] The platform of the gem; defaults to the platform of a version object.
      # @return [String] the message the endpoint answers with
      # @raise [NoLatestVersion] if no version is given and the gem has no published version
      # @example
      #   Gems.yank "gemcutter", "0.2.1", platform: "x86-darwin-10"
      # @example
      #   Gems.yank Gems.version("gemcutter", "0.2.1")
      def yank(gem_name, version = nil, platform: nil)
        version = version_of(gem_name, version)
        platform ||= platform_of(version)
        version = number_of(version) || latest_version(gem_name)
        delete("/api/v1/gems/yank", {gem_name: name_of(gem_name), version:, platform:}.compact)
      end

      # Update a previously yanked gem back into RubyGems.org's index
      #
      # @api public
      # @authenticated true
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version. A version stands in for the
      #   version argument too, so that unyanking a version unyanks that version.
      # @param version [String, Version, nil] The version of a gem (defaults to the version given as the gem, or to
      #   the latest version).
      # @param platform [String, nil] The platform of the gem; defaults to the platform of a version object.
      # @return [String] the message the endpoint answers with
      # @raise [NoLatestVersion] if no version is given and the gem has no published version
      # @example
      #   Gems.unyank "gemcutter", "0.2.1", platform: "x86-darwin-10"
      # @example
      #   Gems.unyank Gems.version("gemcutter", "0.2.1")
      def unyank(gem_name, version = nil, platform: nil)
        version = version_of(gem_name, version)
        platform ||= platform_of(version)
        version = number_of(version) || latest_version(gem_name)
        put("/api/v1/gems/unyank", {gem_name: name_of(gem_name), version:, platform:}.compact)
      end

      # Returns an array of all the reverse dependencies to the given gem
      #
      # @api public
      # @authenticated false
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version
      # @param only [String, nil] Restrict the results to "development" or "runtime" dependencies.
      # @return [Array<String>]
      # @example
      #   Gems.reverse_dependencies "money", only: "runtime"
      def reverse_dependencies(gem_name, only: nil)
        parse_json(get("/api/v1/gems/#{escape(name_of(gem_name))}/reverse_dependencies.json", {only:}.compact))
      end

      private

      # Build the multipart body for pushing a gem with attestations
      #
      # The gem is a field the request reads as a stream, rather than the contents of the file, so that a gem pushed
      # with attestations is no more held in memory than one pushed without them.
      #
      # @api private
      # @param file [File, IO] The open gem file, whose name names the field.
      # @param attestations [Array<String, Pathname, File>] The paths of the attestations, or the open files.
      # @return [Array] the multipart form fields
      def multipart_push_body(file, attestations)
        [
          ["gem", file, {filename: filename_of(file), content_type: RequestBuilder::OCTET_STREAM}],
          ["attestations", "[#{attestations.map { |attestation| read_file(attestation) }.join(",")}]",
            {content_type: "application/json"}]
        ]
      end

      # The name a gem is sent under in a multipart body
      #
      # The name of the file is sent rather than the path it was opened with, so that pushing a gem does not tell
      # the host where the gem sits on the machine it was pushed from. An IO with no path of its own, such as a gem
      # held in memory, is sent under the name of its field rather than raising.
      #
      # @api private
      # @param file [File, IO] the open gem file
      # @return [String] the name of the file, or {UNNAMED_GEM_FILENAME} for an IO with no path
      def filename_of(file)
        file.respond_to?(:to_path) ? File.basename(file) : UNNAMED_GEM_FILENAME
      end

      # Open a file given as a path, or take one that is already open
      #
      # A file the library opens is closed once the request has been sent, and one the caller opened is left open for
      # the caller to close. Either is read in binary mode, so that a gem opened in text mode is sent as the bytes it
      # holds rather than with its line endings translated.
      #
      # @api private
      # @param file [String, Pathname, File] the path, or the open file
      # @yield [file] the open file
      # @return [Object] what the block returns
      def open_file(file, &block)
        case file
        when String, Pathname then File.open(file, "rb", &block)
        else yield file.binmode
        end
      end

      # Read a file given as a path or an open file
      #
      # An open file is read in binary mode, as a path is, so that a file opened in text mode is read as the bytes it
      # holds rather than with its line endings translated.
      #
      # @api private
      # @param file [String, Pathname, File] the path, or the open file
      # @return [String] the contents of the file
      def read_file(file)
        case file
        when String, Pathname then File.binread(file)
        else file.binmode.read #: String
        end
      end
    end
  end
end
