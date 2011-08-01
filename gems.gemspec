# -*- encoding: utf-8 -*-
require File.expand_path('../lib/gems/version', __FILE__)

Gem::Specification.new do |gem|
  gem.add_development_dependency 'ZenTest', '~> 4.5'
  gem.add_development_dependency 'maruku', '~> 0.6'
  gem.add_development_dependency 'rake', '~> 0.9'
  gem.add_development_dependency 'rspec', '~> 2.6'
  gem.add_development_dependency 'simplecov', '~> 0.4'
  gem.add_development_dependency 'webmock', '~> 1.6'
  gem.add_development_dependency 'yard', '~> 0.7'

  gem.authors               = ["Erik Michaels-Ober"]
  gem.email                 = ['sferik@gmail.com']
  gem.description           = %q{Ruby wrapper for the RubyGems.org API}
  gem.summary               = gem.description
  gem.homepage              = 'https://github.com/rubygems/gems'

  gem.executables           = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files                 = `git ls-files`.split("\n")
  gem.test_files            = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name                  = 'gems'
  gem.require_paths         = ['lib']
  gem.required_ruby_version = '>= 1.9'
  gem.version               = Gems::VERSION
end
