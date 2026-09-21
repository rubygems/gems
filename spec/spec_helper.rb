# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

unless $PROGRAM_NAME.include?("mutant") || RUBY_ENGINE.eql?("jruby")
  require "simplecov"

  SimpleCov.start "strict"
end

# The environment `gem push` reads, which the library falls back to until a host, key, or passcode is assigned. A
# developer who has exported one for `gem push` would otherwise have it resolved by the examples that exercise those
# fallbacks, which sends their own credential to the request stubs and leaves it in whatever those runs record. It is
# cleared before the library is required, since the module reads the host as it is loaded.
%w[GEM_HOST_API_KEY GEM_HOST_OTP_CODE RUBYGEMS_HOST].each { |name| ENV.delete(name) }

require "gems"
require "rspec"
require "webmock/rspec"

WebMock.disable_net_connect!

TEST_HOST = "https://rubygems.org"
TEST_KEY = "TEST_KEY"
TEST_USERNAME = "TEST_USERNAME"
TEST_PASSWORD = "TEST_PASSWORD"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # The credentials `gem signin` stores, which the library falls back to for a key it was not given, so that the key
  # in the developer's own ~/.gem/credentials is never the one an example resolves. An example that wants a stored
  # key stubs the configuration again with a key of its own.
  config.before do
    stub_rubygems_configuration(rubygems_api_key: nil)
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

def stub_rubygems_configuration(api_keys: {}, rubygems_api_key: "FILE_KEY")
  allow(Gem).to receive(:configuration).and_return(instance_double(Gem::ConfigFile, rubygems_api_key:, api_keys:))
end

def build_response(response_class, code, message, body)
  response = response_class.new("1.1", code, message)
  response.instance_variable_set(:@read, true)
  response.body = body
  response
end
