require_relative "lib/gems/version"

Gem::Specification.new do |spec|
  spec.name = "gems"
  spec.version = Gems::VERSION
  spec.authors = ["Erik Berlin"]
  spec.email = ["sferik@gmail.com"]

  spec.summary = "Ruby wrapper for the RubyGems.org API"
  spec.description = spec.summary
  spec.homepage = "https://github.com/rubygems/gems"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata = {
    "allowed_push_host" => "https://rubygems.org",
    "bug_tracker_uri" => "https://github.com/rubygems/gems/issues",
    "documentation_uri" => "https://rubydoc.info/gems/gems/",
    "homepage_uri" => spec.homepage,
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/rubygems/gems"
  }

  spec.files = Dir[
    "bin/*",
    "lib/**/*.rb",
    "sig/*.rbs",
    "*.md",
    "LICENSE.md"
  ]
  spec.require_paths = ["lib"]
end
