$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
SimpleCov.start
require 'gems'
require 'rspec'
require 'webmock/rspec'

def rubygems_url(url)
  url =~ /^http/ ? url : 'https://rubygems.org' + url
end

def a_delete(url)
  a_request(:delete, rubygems_url(url))
end

def a_get(url)
  a_request(:get, rubygems_url(url))
end

def a_post(url)
  a_request(:post, rubygems_url(url))
end

def a_put(url)
  a_request(:put, rubygems_url(url))
end

def stub_delete(url)
  stub_request(:delete, rubygems_url(url))
end

def stub_get(url)
  stub_request(:get, rubygems_url(url))
end

def stub_post(url)
  stub_request(:post, rubygems_url(url))
end

def stub_put(url)
  stub_request(:put, rubygems_url(url))
end

def fixture_path
  File.expand_path('../fixtures', __FILE__)
end

def fixture(file)
  File.new(fixture_path + '/' + file)
end
