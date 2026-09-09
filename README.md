# Gems

[![tests](https://github.com/rubygems/gems/actions/workflows/test.yml/badge.svg)](https://github.com/rubygems/gems/actions/workflows/test.yml)
[![mutation tests](https://github.com/rubygems/gems/actions/workflows/mutant.yml/badge.svg)](https://github.com/rubygems/gems/actions/workflows/mutant.yml)
[![linter](https://github.com/rubygems/gems/actions/workflows/lint.yml/badge.svg)](https://github.com/rubygems/gems/actions/workflows/lint.yml)
[![type checker](https://github.com/rubygems/gems/actions/workflows/steep.yml/badge.svg)](https://github.com/rubygems/gems/actions/workflows/steep.yml)
[![gem version](https://badge.fury.io/rb/gems.svg)](https://rubygems.org/gems/gems)

Ruby wrapper for the RubyGems.org API.

## Installation

Install the gem and add to the application's Gemfile:

    bundle add gems

Or, if Bundler is not being used to manage dependencies:

    gem install gems

## Documentation
[https://www.rubydoc.info/gems/gems](https://www.rubydoc.info/gems/gems)

# Usage Examples

```ruby
require 'gems'

# Return some basic information about rails.
gem = Gems.gem 'rails'
gem.name             # => "rails"
gem.version          # => "8.1.2"
gem.downloads        # => 704478420
gem.runtime_dependencies.map(&:name) # => ["actioncable", "actionmailbox", ...]

# Return some basic information about rails version 7.0.6.
version = Gems.version 'rails', '7.0.6'
version.number       # => "7.0.6"
version.built_at     # => 2023-06-29 00:00:00 UTC
version.sha          # => "5dfbd481..."

# Return an array of active gems that match the query.
Gems.search 'cucumber'

# Return all gems that you own.
Gems.owned_gems

# Return all gems owned by Erik Berlin.
Gems.owned_gems 'sferik'

# Submit a gem to RubyGems.org.
Gems.push File.new 'gemcutter-0.2.1.gem'

# Remove a gem from RubyGems.org's index.
# Defaults to the latest version if no version is specified.
Gems.yank 'bills', '0.0.1'

# Update a previously yanked gem back into RubyGems.org's index.
# Defaults to the latest version if no version is specified.
Gems.unyank 'bills', '0.0.1'

# Return an array of versions of coulda.
Gems.versions('coulda').map(&:number)

# Return the latest version of coulda.
Gems.latest_version 'coulda'

# Return the total number of downloads of all gems.
Gems.total_downloads

# Return the number of downloads of rails_admin and of version 0.0.1.
# (Defaults to the latest version if no version is specified.)
Gems.downloads('rails_admin', '0.0.1').version_downloads

# Returns an array containing the top 50 downloaded gem versions of all time.
Gems.most_downloaded.first.full_name

# View all owners of a gem that you own.
Gems.owners('gemcutter').map(&:handle)

# Add an owner to a RubyGem you own, giving that user permission to manage it.
Gems.add_owner 'gemcutter', 'josh@technicalpickles.com'

# Remove a user's permission to manage a RubyGem you own.
Gems.remove_owner 'gemcutter', 'josh@technicalpickles.com'

# Return all the webhooks registered under your account.
Gems.web_hooks.map(&:url)

# Add a webhook.
Gems.add_web_hook 'rails', 'http://example.com'

# Remove a webhook.
Gems.remove_web_hook 'rails', 'http://example.com'

# Test fire a webhook.
Gems.fire_web_hook 'rails', 'http://example.com'

# Returns the 50 gems most recently added to RubyGems.org
Gems.latest

# Returns the 50 most recently updated gems
Gems.just_updated

# Create an API key using HTTP basic authentication.
# The key is only returned once, so store it somewhere safe.
Gems.configure do |config|
  config.username = 'nick@gemcutter.org'
  config.password = 'schwwwwing'
end
Gems.create_api_key('ci-push', push_rubygem: true).key

# Update the scopes of an API key.
Gems.update_api_key 'rubygems_701243f217cdf23b1370c7b66b65ca97', yank_rubygem: true

# Exchange an OIDC ID token for an API key via trusted publishing.
Gems.exchange_trusted_publisher_token(ENV.fetch('ID_TOKEN')).key

# The following methods require authentication.
# By default, we load your API key from ~/.gem/credentials
# You can override this default by specifying a custom API key.
Gems.configure do |config|
  config.key = '701243f217cdf23b1370c7b66b65ca97'
end

# If your account requires multi-factor authentication, provide a one-time passcode.
Gems.configure do |config|
  config.otp = '123456'
end

# For trusted publishing, provide an OIDC ID token instead of an API key.
# It is exchanged for an API key on the first request.
Gems.configure do |config|
  config.id_token = ENV.fetch('ID_TOKEN')
end

# Alternatively, create a client with its own credentials and settings.
client = Gems::Client.new(key: '701243f217cdf23b1370c7b66b65ca97', host: 'https://gems.example.com')
client.gem 'rails'
```

## Response objects

Responses are wrapped in objects with readers for each documented field: `Gems::Gem`, `Gems::Version`,
`Gems::Dependency`, `Gems::Owner`, `Gems::WebHook`, `Gems::Downloads`, and `Gems::ApiKey`. Timestamps are parsed into
`Time` objects and boolean fields have predicate readers such as `yanked?`. Objects are accepted wherever their
identifier is expected, so `Gems.versions(gem)`, `Gems.remove_owner(gem, owner)`, and `Gems.key = api_key` all work.
Every object also exposes the raw response through `[]` and `to_h`, so fields without a reader remain accessible:

```ruby
gem = Gems.gem 'rails'
gem['dependencies'] # => {"development" => [...], "runtime" => [...]}
gem.to_h            # => the parsed JSON response
```

## Configuration

Clients default to the global configuration, which can be set with `Gems.configure` or overridden per client:

| Option        | Description                                              | Default                                |
| ------------- | -------------------------------------------------------- | -------------------------------------- |
| `host`        | The RubyGems-compatible host, including scheme           | `RUBYGEMS_HOST` or `https://rubygems.org` |
| `key`         | The API key sent in the `Authorization` header           | `~/.gem/credentials`                   |
| `username`    | The username for HTTP basic authentication               | `nil`                                  |
| `password`    | The password for HTTP basic authentication               | `nil`                                  |
| `otp`         | The one-time passcode sent in the `OTP` header           | `nil`                                  |
| `id_token`    | The OIDC ID token exchanged for an API key               | `nil`                                  |
| `user_agent`  | The `User-Agent` header                                  | `Gems <version>`                       |
| `open_timeout` | The timeout for opening connections, in seconds         | `60`                                   |
| `read_timeout` | The timeout for reading responses, in seconds           | `60`                                   |
| `write_timeout` | The timeout for writing requests, in seconds           | `60`                                   |
| `debug_output` | An IO that receives HTTP debug output                   | `nil`                                  |
| `proxy_url`   | The proxy to use                                         | `http_proxy`/`https_proxy` environment |
| `max_redirects` | The maximum number of redirects to follow              | `10`                                   |

Each authentication method has its own authenticator class: `Gems::ApiKeyAuthenticator`, `Gems::BasicAuthenticator`,
`Gems::TrustedPublisherAuthenticator`, and `Gems::OtpAuthenticator` (which wraps one of the others).
HTTP basic authentication takes precedence over trusted publishing, which takes precedence over the API key.

Proxies are read from the `http_proxy`, `https_proxy`, and `no_proxy` environment variables unless `proxy_url` is set.

## Errors

All errors inherit from `Gems::Error`. HTTP errors are `Gems::HTTPError` subclasses that expose the `response` and
status `code`, with specific classes such as `Gems::NotFound`, `Gems::Unauthorized`, and `Gems::Forbidden`.
Network failures raise `Gems::NetworkError` and redirect loops raise `Gems::TooManyRedirects`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake` to run the tests,
linters, mutation tests, type checker, and documentation checks. Coverage, mutation testing, and type checking need
Ruby 3.3 or later; on older Rubies those tasks are skipped. You can also run `bin/console` for an interactive prompt
that will allow you to experiment.

## Supported Ruby Versions
This library aims to support and is [tested against][gh-actions] the following Ruby
implementations:

* Ruby 3.1
* Ruby 3.2
* Ruby 3.3
* Ruby 3.4
* [JRuby][]

[gh-actions]: https://github.com/rubygems/gems/actions
[jruby]: https://www.jruby.org/

If something doesn't work on one of these interpreters, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby
implementations, however support will only be provided for the versions listed
above.

If you would like this library to support another Ruby version, you may
volunteer to be a maintainer. Being a maintainer entails making sure all tests
run and pass on that implementation. When something breaks on your
implementation, you will be responsible for providing patches in a timely
fashion. If critical issues for a particular implementation exist at the time
of a major release, support for that Ruby version may be dropped.

## Copyright
Copyright (c) 2011-2026 Erik Berlin. See [LICENSE][] for details.

[license]: LICENSE.md
