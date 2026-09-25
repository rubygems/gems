# frozen_string_literal: true

require "pathname"
require_relative "../identifiers"
require_relative "../json_parsing"
require_relative "../pagination"
require_relative "../path_escaping"
require_relative "../dependency"
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
      # @param attestations [Array<String, Pathname, File>, String, Pathname, File, nil] The paths of the
      #   attestations to push, or the open files, one of either, or `nil`.
      # @return [String] the message the endpoint answers with
      # @example
      #   Gems.push "pkg/gemcutter-0.2.1.gem"
      # @example
      #   Gems.push File.new("pkg/gemcutter-0.2.1.gem"), host: "https://gems.example.com"
      # @example
      #   Gems.push "pkg/gemcutter-0.2.1.gem", attestations: "pkg/gemcutter-0.2.1.gem.sigstore.json"
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
      # @param version [String, Version, nil] The version of a gem (defaults to the version given as the gem). There
      #   is no default beyond that: a yank cannot be undone, so the version it removes is always named.
      # @param platform [String, nil] The platform of the gem; defaults to the platform of a version object.
      # @param ruby_abi [String, nil] The Ruby ABI a version of the platform was built for, such as "3.4"; defaults to
      #   the Ruby ABI of a version object, or to the version built for none.
      # @return [String] the message the endpoint answers with
      # @raise [ArgumentError] if no version is given, as the version argument or as the gem
      # @example
      #   Gems.yank "gemcutter", "0.2.1", platform: "x86-darwin-10"
      # @example
      #   Gems.yank "gemcutter", "0.2.1", platform: "x86_64-linux", ruby_abi: "3.4"
      # @example
      #   Gems.yank Gems.version("gemcutter", "0.2.1")
      def yank(gem_name, version = nil, platform: nil, ruby_abi: nil)
        version = version_of(gem_name, version)
        platform ||= platform_of(version)
        ruby_abi ||= ruby_abi_of(version)
        number = number_of(version)
        raise ArgumentError, "No version of #{name_of(gem_name)} given to yank" if number.nil?

        delete("/api/v1/gems/yank", {gem_name: name_of(gem_name), version: number, platform:, ruby_abi:}.compact)
      end

      # Returns an array of all the reverse dependencies to the given gem
      #
      # @api public
      # @authenticated false
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version
      # @param only [String, Symbol, nil] Restrict the results to "development" or "runtime" dependencies, which
      #   are the types {Dependency::TYPES} names.
      # @return [Array<String>]
      # @raise [ArgumentError] if the type is not one the API defines
      # @example
      #   Gems.reverse_dependencies "money", only: "runtime"
      def reverse_dependencies(gem_name, only: nil)
        validate_type(only)
        parse_json(get("/api/v1/gems/#{escape(name_of(gem_name))}/reverse_dependencies.json", {only:}.compact))
      end

      # Returns the full names of the versions that depend on the given gem
      #
      # Where {#reverse_dependencies} names each gem that depends on the gem once, this names every indexed version
      # of those gems that does, at every platform, such as "foreman-0.63.0-java", with dependencies of both types.
      #
      # @api public
      # @authenticated false
      # @param gem_name [String, Gem, Version] The name of a gem, or a gem or version
      # @return [Array<String>] the full names of the versions
      # @example
      #   Gems.reverse_dependency_versions "dotenv"
      def reverse_dependency_versions(gem_name)
        parse_json(get("/api/v1/versions/#{escape(name_of(gem_name))}/reverse_dependencies.json"))
      end

      private

      # Check that a dependency type is one the RubyGems API defines
      #
      # The endpoint answers with every reverse dependency for a type it does not define, rather than refusing it,
      # so a misspelled type would be answered with the dependencies of both types where the caller asked for one.
      #
      # @api private
      # @param type [String, Symbol, nil] the dependency type, or nil to ask for both
      # @return [void]
      # @raise [ArgumentError] if the type is not one the API defines
      def validate_type(type)
        return if type.nil? || Dependency::TYPES.include?(type.to_s)

        raise ArgumentError, "Unknown dependency type: #{type}. " \
          "The types the API defines are: #{Dependency::TYPES.join(", ")}"
      end

      # Build the multipart body for pushing a gem with attestations
      #
      # The gem is a field the request reads as a stream, rather than the contents of the file, so that a gem pushed
      # with attestations is no more held in memory than one pushed without them.
      #
      # @api private
      # @param file [File, IO] The open gem file, whose name names the field.
      # @param attestations [Array<String, Pathname, File>, String, Pathname, File] The paths of the attestations,
      #   or the open files, or one of either.
      # @return [Array] the multipart form fields
      def multipart_push_body(file, attestations)
        [
          ["gem", file, {filename: filename_of(file), content_type: RequestBuilder::OCTET_STREAM}],
          ["attestations", "[#{list_of(attestations).map { |attestation| read_file(attestation) }.join(",")}]",
            {content_type: "application/json"}]
        ]
      end

      # The attestations to push, as a list
      #
      # A gem is usually pushed with one attestation, so one given on its own is taken as the list it names rather
      # than raising. `Array()` is not used for this: it would read an open file as the lines it holds.
      #
      # @api private
      # @param attestations [Array<String, Pathname, File>, String, Pathname, File] the attestations
      # @return [Array<String, Pathname, File>] the attestations, as a list
      def list_of(attestations)
        case attestations
        when Array then attestations
        else [attestations]
        end
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
