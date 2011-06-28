$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
SimpleCov.start
require 'gems'
require 'rspec'
require 'webmock/rspec'

def a_get(path)
  a_request(:get, 'https://nick%40gemcutter.org:schwwwwing@rubygems.org' + path)
end

def stub_get(path)
  stub_request(:get, 'https://nick%40gemcutter.org:schwwwwing@rubygems.org' + path)
end

def fixture_path
  File.expand_path('../fixtures', __FILE__)
end

def fixture(file)
  File.new(fixture_path + '/' + file)
end
