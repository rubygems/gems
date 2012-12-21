# encoding: utf-8
require File.expand_path('../lib/gems/version', __FILE__)

Gem::Specification.new do |spec|
  spec.add_development_dependency 'kaminari'
  spec.add_development_dependency 'simplecov'
  spec.authors     = ["Erik Michaels-Ober"]
  spec.description = %q{Ruby wrapper for the RubyGems.org API}
  spec.email       = ['sferik@gmail.com']
  spec.files       = `git ls-files`.split("\n")
  spec.files       = %w(.yardopts CONTRIBUTING.md LICENSE.md README.md Rakefile gems.gemspec)
  spec.files      += Dir.glob("lib/**/*.rb")
  spec.files      += Dir.glob("spec/**/*")
  spec.homepage    = 'https://github.com/rubygems/gems'
  spec.licenses    = ['MIT']
  spec.name        = 'gems'
  spec.require_paths = ['lib']
  spec.summary     = spec.description
  spec.test_files  = Dir.glob("spec/**/*")
  spec.version     = Gems::VERSION
end
