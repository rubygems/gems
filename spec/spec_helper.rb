$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

unless RUBY_ENGINE.eql?("jruby")
  require "simplecov"

  SimpleCov.start do
    enable_coverage :branch
    minimum_coverage line: 100
  end
end

require "gems"
require "rspec"
require "webmock/rspec"

WebMock.disable_net_connect!

TEST_HOST = "https://rubygems.org".freeze
TEST_KEY = "TEST_KEY".freeze
TEST_USERNAME = "TEST_USERNAME".freeze
TEST_PASSWORD = "TEST_PASSWORD".freeze

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after do
    Gems.reset
  end
end

def fixture_path
  File.expand_path("fixtures", __dir__)
end

def fixture(file)
  File.new(File.join(fixture_path, file), "rb")
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

def stub_delete(url)
  stub_request(:delete, rubygems_url(url))
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

def a_delete(url)
  a_request(:delete, rubygems_url(url))
end

def rubygems_url(url)
  return url if url.start_with?("http")

  TEST_HOST + url
end

def build_response(response_class, code, message, body)
  response = response_class.new("1.1", code, message)
  response.instance_variable_set(:@read, true)
  response.body = body
  response
end
