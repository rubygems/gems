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
require "openssl"
require "rspec"
require "tmpdir"
require "webmock/rspec"

# A certificate authority for the examples that name one, generated rather than committed so that the repository
# carries no PEM private key for a secret scanner to flag, and written into a directory of its own so that a path
# to a file of certificates and a path to a directory of them are both at hand
def build_test_certificate(key)
  name = OpenSSL::X509::Name.parse("/CN=Gems Test CA")
  fields = {version: 2, serial: 1, subject: name, issuer: name, public_key: key,
            not_before: Time.now - 60, not_after: Time.now + 3600}
  OpenSSL::X509::Certificate.new.tap do |certificate|
    fields.each { |field, value| certificate.public_send(:"#{field}=", value) }
    certificate.sign(key, OpenSSL::Digest.new("SHA256"))
  end
end

TEST_CERTIFICATE_DIRECTORY = Dir.mktmpdir("gems-certificates")
# Only the process that made the directory removes it: mutant forks a process per mutation, and a fork removing it
# on the way out would take it from the mutations that run after
TEST_CERTIFICATE_PID = Process.pid
at_exit { FileUtils.remove_entry(TEST_CERTIFICATE_DIRECTORY, true) if Process.pid.eql?(TEST_CERTIFICATE_PID) }
File.write(File.join(TEST_CERTIFICATE_DIRECTORY, "ca.pem"),
  build_test_certificate(OpenSSL::PKey::EC.generate("prime256v1")).to_pem)

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

def certificate_path(file = nil)
  File.join(TEST_CERTIFICATE_DIRECTORY, *file)
end

def test_client_cert
  OpenSSL::X509::Certificate.new(File.read(certificate_path("ca.pem")))
end

def test_client_key
  OpenSSL::PKey::EC.generate("prime256v1")
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
