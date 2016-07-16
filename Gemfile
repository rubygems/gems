source 'https://rubygems.org'

gem 'rake'
gem 'yard'
gem 'jruby-openssl', :platforms => :jruby
gem 'json', '< 2.0', :platforms => :mri_19

group :development do
  gem 'pry'
end

group :test do
  gem 'backports'
  gem 'coveralls'
  gem 'rspec', '>= 3.1.0'
  gem 'rubocop', '>= 0.27'
  gem 'simplecov', '>= 0.9'
  gem 'webmock', '< 2.0'
  gem 'yardstick'
end

gemspec
