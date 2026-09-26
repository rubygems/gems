# frozen_string_literal: true

require_relative "lib/gems/library_version"

Gem::Specification.new do |spec|
  spec.name = "gems"
  spec.version = Gems::VERSION
  spec.authors = ["Erik Berlin"]
  spec.email = ["sferik@gmail.com"]

  spec.summary = "Ruby wrapper for the RubyGems.org API"
  spec.description = "A client for the RubyGems.org API and compatible hosts, with immutable response objects, " \
    "trusted publishing, and retries"
  spec.homepage = "https://github.com/rubygems/gems"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4.0"

  spec.metadata = {
    "allowed_push_host" => "https://rubygems.org",
    "bug_tracker_uri" => "https://github.com/rubygems/gems/issues",
    "changelog_uri" => "https://github.com/rubygems/gems/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://rubydoc.info/gems/gems/",
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/rubygems/gems"
  }

  spec.files = Dir.glob([
    ".yardopts",
    "lib/**/*.rb",
    "sig/*.rbs",
    "sig/manifest.yaml",
    "*.md",
    "LICENSE.md"
  ], base: __dir__)
  spec.require_paths = ["lib"]
end
