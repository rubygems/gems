source 'https://rubygems.org'

gem 'rake'
gem 'yard'
gem 'jruby-openssl', :platforms => :jruby

group :development do
  gem 'pry'
  platforms :ruby_19, :ruby_20 do
    gem 'pry-debugger'
    gem 'pry-stack_explorer'
  end
end

group :test do
  gem 'backports'
  gem 'coveralls'
  gem 'json', :platforms => [:rbx, :ruby_19, :ruby_18]
  gem 'mime-types', '~> 1.25', :platforms => [:jruby, :ruby_18]
  gem 'rest-client', '~> 1.6.0', :platforms => [:jruby, :ruby_18]
  gem 'rspec', '>= 2.11'
  gem 'rubocop', '>= 0.23', :platforms => [:ruby_19, :ruby_20, :ruby_21]
  gem 'simplecov', '>= 0.9'
  gem 'webmock'
  gem 'yardstick'
end

gemspec
