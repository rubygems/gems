source 'https://rubygems.org'

gem 'rake'
gem 'yard'
gem 'jruby-openssl', :platforms => :jruby

group :test do
  gem 'coveralls', :require => false
  gem 'mime-types', '~> 1.25', :platforms => [:jruby, :ruby_18]
  gem 'rspec', '>= 2.11'
  gem 'simplecov', :require => false
  gem 'webmock'
end

platforms :rbx do
  gem 'rubinius-coverage', '~> 2.0'
  gem 'rubysl', '~> 2.0'
  gem 'rubysl-json', '~> 2.0'
end

gemspec
