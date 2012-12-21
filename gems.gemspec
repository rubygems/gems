# encoding: utf-8
require File.expand_path('../lib/gems/version', __FILE__)

Gem::Specification.new do |gem|
  gem.add_development_dependency 'kaminari'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'webmock'
  gem.add_development_dependency 'yard'
  gem.authors     = ["Erik Michaels-Ober"]
  gem.description = %q{Ruby wrapper for the RubyGems.org API}
  gem.email       = ['sferik@gmail.com']
  gem.files       = `git ls-files`.split("\n")
  gem.homepage    = 'https://github.com/rubygems/gems'
  gem.name        = 'gems'
  gem.require_paths = ['lib']
  gem.summary     = gem.description
  gem.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.version     = Gems::VERSION
end
