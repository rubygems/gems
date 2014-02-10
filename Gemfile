source 'https://rubygems.org'

gem 'rake'
gem 'yard'
gem 'jruby-openssl', :platforms => :jruby

group :development do
  gem 'pry'
  gem 'pry-rescue'
  platforms :ruby_19, :ruby_20 do
    gem 'pry-debugger'
    gem 'pry-stack_explorer'
  end
end

group :test do
  gem 'backports'
  gem 'coveralls', :require => false
  gem 'json', :platforms => [:rbx, :ruby_19]
  gem 'mime-types', '~> 1.25', :platforms => [:jruby, :ruby_18]
  gem 'rubocop', '>= 0.16', :platforms => [:ruby_19, :ruby_20, :ruby_21]
  gem 'rspec', '>= 2.11'
  gem 'simplecov', :require => false
  gem 'webmock'
  gem 'yardstick'
end

gemspec
