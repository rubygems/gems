# -*- encoding: utf-8 -*-
require File.expand_path('../lib/gems/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Erik Michaels-Ober"]
  gem.email         = ['sferik@gmail.com']
  gem.description   = %q{Ruby wrapper for the RubyGems.org API}
  gem.summary       = gem.description
  gem.homepage      = 'https://github.com/sferik/gems'

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = 'gems'
  gem.require_paths = ['lib']
  gem.version       = Gems::VERSION
end
