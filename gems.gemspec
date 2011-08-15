# encoding: utf-8
require File.expand_path('../lib/gems/version', __FILE__)

Gem::Specification.new do |gem|
  gem.add_development_dependency 'maruku', '~> 0.6'
  gem.add_development_dependency 'rake', '~> 0.9'
  gem.add_development_dependency 'rspec', '~> 2.6'
  gem.add_development_dependency 'simplecov', '~> 0.4'
  gem.add_development_dependency 'webmock', '~> 1.7'
  gem.add_development_dependency 'yard', '~> 0.7'
  gem.authors     = ["Erik Michaels-Ober"]
  gem.description = %q{Ruby wrapper for the RubyGems.org API}
  gem.email       = ['sferik@gmail.com']
  gem.files       = `git ls-files`.split("\n")
  gem.homepage    = 'https://github.com/rubygems/gems'
  gem.name        = 'gems'
  gem.require_paths = ['lib']
  gem.required_ruby_version = '>= 1.9'
  gem.summary     = gem.description
  gem.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.version     = Gems::VERSION
end
