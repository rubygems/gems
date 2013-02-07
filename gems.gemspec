# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gems/version'

Gem::Specification.new do |spec|
  spec.add_development_dependency 'bundler', '~> 1.0'
  spec.authors     = ["Erik Michaels-Ober"]
  spec.cert_chain  = ['certs/sferik.pem']
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
  spec.signing_key = File.expand_path("~/.gem/private_key.pem") if $0 =~ /gem\z/
  spec.summary     = spec.description
  spec.test_files  = Dir.glob("spec/**/*")
  spec.version     = Gems::VERSION
end
