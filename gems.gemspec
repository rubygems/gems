# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gems/version'

Gem::Specification.new do |spec|
  spec.add_development_dependency 'bundler', '~> 1.0'
  spec.authors       = ['Erik Michaels-Ober']
  spec.description   = 'Ruby wrapper for the RubyGems.org API'
  spec.email         = ['sferik@gmail.com']
  spec.files         = %w(.yardopts CONTRIBUTING.md LICENSE.md README.md gems.gemspec) + Dir['lib/**/*.rb']
  spec.homepage      = 'https://github.com/rubygems/gems'
  spec.licenses      = %w(MIT)
  spec.name          = 'gems'
  spec.require_paths = %w(lib)
  spec.required_ruby_version = '>= 1.9.3'
  spec.summary       = spec.description
  spec.version       = Gems::VERSION
  spec.add_runtime_dependency 'multi_json'
end
