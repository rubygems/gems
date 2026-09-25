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

Upgrading from 2.x? See [UPGRADING.md](UPGRADING.md) for what changed.

# Usage Examples

```ruby
require 'gems'

# Return some basic information about rails.
gem = Gems.rubygem 'rails'
gem.name             # => "rails"
gem.version          # => "8.1.3.1"
gem.downloads        # => 704478420
gem.runtime_dependencies.map(&:name) # => ["actioncable", "actionmailbox", ...]

# Return some basic information about rails version 7.0.6.
version = Gems.version 'rails', '7.0.6'
version.number       # => "7.0.6"
version.built_at     # => 2023-06-29 00:00:00 UTC
version.sha          # => "5dfbd481...", the checksum of the gem file
version.spec_sha     # => "9c8cfe74...", the checksum of the gemspec it was pushed with
version.runtime_dependencies.map(&:name) # => ["actioncable", "actionmailbox", ...]

# Return information about a version for a specific platform.
Gems.version 'nokogiri', '1.15.0', platform: 'java'

# Return information about the version of a platform built for a specific Ruby ABI.
Gems.version 'nokogiri', '1.15.0', platform: 'x86_64-linux', ruby_abi: '3.4'

# Defaults to the latest version if no version is specified.
Gems.version 'rails'

# Return the SHA-256 checksum of every file in a version.
Gems.contents('rails', '8.1.3.1')['README.md']['sha256']

# Return the sigstore attestations published with a version.
Gems.attestations 'rails', '8.1.3.1'
Gems.attestations 'nokogiri', '1.15.0', platform: 'java'

# Return an array of active gems that match the query.
Gems.search 'cucumber'

# Walk every page of results, a page at a time, without tracking page numbers.
Gems.search_each('cucumber').first(100)
Gems.search_each('cucumber') { |gem| puts gem.name }

# Return the names of gems that match the query, for a search box.
Gems.autocomplete 'nokogiri'

# Return all gems that you own.
Gems.owned_gems

# Return all gems owned by Erik Berlin.
Gems.owned_gems 'sferik'

# Return basic information about a user, by handle or ID.
Gems.profile('sferik').handle

# Submit a gem to RubyGems.org, given as a path or an open file.
# The gem is sent as a stream, so a large gem is never held in memory.
Gems.push 'gemcutter-0.2.1.gem'
Gems.push File.new 'gemcutter-0.2.1.gem'

# Push the sigstore attestations a gem was signed with, one or several.
Gems.push 'gemcutter-0.2.1.gem', attestations: 'gemcutter-0.2.1.gem.sigstore.json'

# Remove a gem from RubyGems.org's index.
# Defaults to the latest version if no version is specified.
Gems.yank 'bills', '0.0.1'

# A gem or version object stands in for both the gem and the version.
Gems.yank Gems.version('bills', '0.0.1')
Gems.contents Gems.rubygem('rails')

# Return an array of versions of coulda, and the newest of them.
Gems.versions('coulda').map(&:number)
Gems.versions('coulda').max.number

# Return the latest version of coulda.
Gems.latest_version 'coulda'

# Return the total number of downloads of all gems.
Gems.total_downloads

# Return the number of downloads of rails_admin and of version 0.0.1.
# (Defaults to the latest version if no version is specified.)
Gems.downloads('rails_admin', '0.0.1').version_downloads

# The counts name the version they are for, which the endpoint answers without.
Gems.downloads('rails_admin', '0.0.1').full_name

# Return the downloads of a version for a specific platform.
Gems.downloads('nokogiri', '1.15.0', platform: 'java').version_downloads

# Returns an array containing the top 50 downloaded gem versions of all time.
Gems.most_downloaded.first.full_name

# View all owners of a gem.
Gems.owners('gemcutter').map(&:handle)

# Add an owner to a RubyGem you own, giving that user permission to manage it.
Gems.add_owner 'gemcutter', 'josh@technicalpickles.com'

# Add a maintainer, who can push but cannot manage owners.
Gems.add_owner 'gemcutter', 'josh@technicalpickles.com', role: 'maintainer'

# Change the role of an existing owner.
Gems.update_owner 'gemcutter', 'josh@technicalpickles.com', role: 'owner'

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

# Returns the 50 gems most recently added to RubyGems.org.
# This endpoint and the one below have no further pages to ask for.
Gems.latest

# Returns the 50 most recently updated gems.
Gems.just_updated

# Returns the gem versions created in a timeframe of up to seven days, 30 at a time.
Gems.timeframe_versions from: Time.now - 86_400
Gems.timeframe_versions from: '2019-01-18T21:24:29Z', to: '2019-01-19T21:24:29Z', page: 2
Gems.timeframe_versions_each(from: Time.now - 86_400).count

# Create an API key using HTTP basic authentication.
# The key is only returned once, so store it somewhere safe.
Gems.configure do |config|
  config.username = 'nick@gemcutter.org'
  config.password = 'schwwwwing'
end
Gems.create_api_key('ci-push', scopes: %i[push_rubygem]).key

# Create a key restricted to one gem that expires in a day and requires a one-time passcode.
Gems.create_api_key('ci-push', scopes: %i[push_rubygem], rubygem_name: 'gems', expires_at: Time.now + 86_400, mfa: true)

# Return your own profile, including its multi-factor authentication level.
Gems.me.mfa

# Update the scopes of an API key, which is granted these alone.
Gems.update_api_key 'rubygems_701243f217cdf23b1370c7b66b65ca97', scopes: %i[push_rubygem yank_rubygem]

# The scopes the API defines, which a misspelled scope is checked against.
Gems::APIKey::SCOPES

# Exchange an OIDC ID token for an API key via trusted publishing.
Gems.exchange_trusted_publisher_token(ENV.fetch('ID_TOKEN')).key

# List your API key roles, and exchange an OIDC ID token for an API key by assuming one.
Gems.api_key_roles.map(&:name)
Gems.assume_api_key_role('0123456789abcdef0123456789abcdef', ENV.fetch('ID_TOKEN')).key

# Trust a GitHub Actions workflow to publish a gem, so that it can push without an API key.
Gems.add_trusted_publisher('gems', repository_owner: 'rubygems', repository_name: 'gems',
  workflow_filename: 'push_gem.yml')

# Restrict a trusted publisher to one GitHub Actions environment.
Gems.add_trusted_publisher('gems', repository_owner: 'rubygems', repository_name: 'gems',
  workflow_filename: 'push_gem.yml', environment: 'release')

# Trust a reusable workflow that lives in another repository.
Gems.add_trusted_publisher('gems', repository_owner: 'rubygems', repository_name: 'gems',
  workflow_filename: 'release.yml', workflow_repository_owner: 'rubygems',
  workflow_repository_name: 'workflows')

# List the trusted publishers of a gem, and read one of them.
Gems.trusted_publishers('gems').map(&:name)
Gems.trusted_publisher('gems', 1).workflow_filename

# Stop trusting a publisher.
Gems.remove_trusted_publisher 'gems', Gems.trusted_publishers('gems').first

# The methods that act on your account or your gems, such as push, yank, and the owner, web hook, API key, and
# trusted publisher methods above, require authentication.
# By default, we load your API key as `gem push` does: from GEM_HOST_API_KEY, or from
# ~/.gem/credentials, where `gem signin` stores it (`gem signin --host` for another host).
# You can override this default by specifying a custom API key.
Gems.configure do |config|
  config.key = 'rubygems_701243f217cdf23b1370c7b66b65ca97'
end

# If your account requires multi-factor authentication, provide a one-time passcode.
# By default, we load it as `gem push` does: from GEM_HOST_OTP_CODE.
Gems.configure do |config|
  config.otp = '123456'
end

# For trusted publishing, provide an OIDC ID token instead of an API key.
# It is exchanged for an API key on the first request.
Gems.configure do |config|
  config.id_token = ENV.fetch('ID_TOKEN')
end

# The methods of the Gems module share one client, Gems.client, which is built again only when the
# configured host or ID token changes, or the key it falls back to when none is configured; any other
# change to the configuration is applied to the client it has. Use it for raw requests.
Gems.client.get '/api/v1/gems/rails.json'

# Raw requests take headers of your own, alongside the User-Agent and the credentials of the client.
Gems.client.get '/api/v1/gems/rails.json', headers: {'X-Trace-Id' => 'abc123'}

# A raw request takes a path on the client's host. Send one to another host with host:, which uses the key
# stored for it; a path that is a URL of another host raises ArgumentError rather than taking the
# credentials of this one there.
Gems.client.get '/api/v1/gems/rails.json', host: 'https://gems.example.com'

# Alternatively, create a client with its own credentials and settings.
client = Gems::Client.new(key: 'rubygems_701243f217cdf23b1370c7b66b65ca97', host: 'https://gems.example.com')
client.rubygem 'rails'

# Given a block, the client is closed once the block is done with it, and the block's value is returned.
versions = Gems::Client.new(host: 'https://gems.example.com') { |client| client.versions 'rails' }
```

## Response objects

Responses are wrapped in objects with readers for each documented field: `Gems::Gem`, `Gems::Version`,
`Gems::Dependency`, `Gems::Owner`, `Gems::Profile`, `Gems::WebHook`, `Gems::Downloads`, `Gems::APIKey`, and
`Gems::TrustedPublisher`.
Timestamps are parsed into `Time` objects and boolean fields have predicate readers such as `yanked?`. A gem and a
version read the dependencies the endpoint they came from answered with as `runtime_dependencies` and
`development_dependencies`; the endpoints that answer without them, such as the versions of a gem, leave both
empty. Objects are
accepted wherever their identifier is expected, so `Gems.versions(gem)`, `Gems.remove_owner(gem, owner)`,
`Gems.remove_trusted_publisher(gem, trusted_publisher)`, and `Gems.key = api_key` all work. A gem or version given
where a gem is expected stands in for the version too, when it carries a version number, so `Gems.version(gem)`,
`Gems.contents(gem)`, `Gems.attestations(gem)`, `Gems.downloads(gem)`, and `Gems.yank(gem)` act on the version it
names, at the platform and Ruby ABI it names, rather than on the latest version. Those five methods take no version
at all when you mean the latest one. RubyGems.org looks the downloads and attestations of a version up by a full name,
which for a version built for a Ruby ABI is a content address it answers with only in the versions `most_downloaded`
returns, so `downloads` and `attestations` raise `ArgumentError` for any other version built for one rather than
answer for the version of its platform built for none.
Objects match `case`/`in` patterns by their readers, so `case gem in {name:, version:}` binds both.
Objects compare by identity (a gem or version by its name, version number, and platform, and so on), so
`Gems.rubygem('rails') == Gems.rubygem('rails')` even when download counts have changed in between. The counts
`downloads` answers with carry the version they were asked for as `full_name`, since the endpoint answers with the
counts alone, and are compared by it as well as by the counts: the downloads of one gem are not the downloads of
another that happens to have been downloaded as many times. An API key is compared by all of its attributes, its
key among them, so two keys that share a name are not equal. Gems and
versions also order by their number as RubyGems orders numbers, rather than as the strings they are written with, so
`7.0.10` comes after `7.0.9`, where comparing the strings, as `max_by(&:number)` does, puts it before:

```ruby
Gems.versions('rails').sort      # oldest first, prereleases before the versions they lead to
Gems.versions('rails').max       # => #<Gems::Version name="rails" number="8.1.3.1">
version.gem_version              # => the number as a Gem::Version, to compare with one of your own

Gems.search('cucumber').sort     # the endpoints that answer with gems order the same way
Gems.timeframe_versions(from: Time.now - 86_400).max
gem.gem_version                  # => the version as a Gem::Version
```

`Comparable` is deliberately left out, so `<` and `>` are not defined: an object is equal to another by its
identity, whatever fields the endpoint it came from answered with, rather than by what it is ordered alongside.

Objects are immutable, with their attributes frozen at every level. Every object also exposes the raw response
through `[]` and `to_h`, so fields without a reader remain accessible. `to_h` answers with a copy you own and can
change, at every level, since the Hashes, Arrays, and Strings an object holds are frozen too; `attributes` answers
with the frozen Hash the object holds:

```ruby
gem = Gems.rubygem 'rails'
gem['dependencies'] # => {"development" => [...], "runtime" => [...]}
gem.to_h            # => the parsed JSON response, as a Hash you can change
gem.to_h['metadata']['fetched_at'] = Time.now # => the nested values are copies too
gem.attributes      # => the same fields, frozen
gem.to_s            # => '#<Gems::Gem name="rails" version="8.1.3.1">', the summary it inspects as
```

Two endpoints return their JSON as it is, by design, rather than wrapping it: `contents` answers with a plain map of
path to checksum, and `attestations` answers with sigstore bundles, whose shape is defined by sigstore rather than by
RubyGems.org. `reverse_dependencies` and `autocomplete` return arrays of gem names for the same reason, and
`reverse_dependency_versions` an array of the full names of the versions that depend on a gem.

## Pagination

The endpoints that return one page at a time — `search` and `timeframe_versions` — each have an `_each` counterpart
that walks the pages. It returns an `Enumerator`, requests a page only once the results of the page before it have
been enumerated, and stops at the first empty page:

```ruby
Gems.search_each('cucumber').first(100)          # requests only the pages it needs
Gems.search_each('cucumber') { |gem| puts gem.name }
Gems.timeframe_versions_each from: Time.now - 86_400
```

`latest` and `just_updated` take no page: the endpoints answer with the 50 gems they name whatever page is asked
for, so there is nothing further to walk.

## Configuration

Clients default to the global configuration, which can be set with `Gems.configure` or overridden per client:

| Option        | Description                                              | Default                                |
| ------------- | -------------------------------------------------------- | -------------------------------------- |
| `host`        | The RubyGems-compatible host, including scheme           | `RUBYGEMS_HOST` or `https://rubygems.org` |
| `key`         | The API key sent in the `Authorization` header           | `GEM_HOST_API_KEY` or the key stored for that host in `~/.gem/credentials` |
| `username`    | The username for HTTP basic authentication               | `nil`                                  |
| `password`    | The password for HTTP basic authentication               | `nil`                                  |
| `otp`         | The one-time passcode sent in the `OTP` header           | `GEM_HOST_OTP_CODE`                    |
| `id_token`    | The OIDC ID token exchanged for an API key               | `nil`                                  |
| `user_agent`  | The `User-Agent` header                                  | `gems/<version> (<ruby> <version>; <platform>)` |
| `open_timeout` | The timeout for opening connections, in seconds         | `60`                                   |
| `read_timeout` | The timeout for reading responses, in seconds           | `60`                                   |
| `write_timeout` | The timeout for writing requests, in seconds           | `60`                                   |
| `keep_alive_timeout` | The seconds an idle connection is kept open for the next request | `2`                   |
| `debug_output` | An IO that receives HTTP debug output, with credentials redacted | `nil`                          |
| `proxy_url`   | The proxy to use                                         | `http_proxy`/`https_proxy` environment |
| `max_redirects` | The maximum number of redirects to follow              | `10`                                   |
| `max_retries` | The number of times a request that was turned away is sent again | `2`                           |
| `max_retry_delay` | The longest a request waits before it is sent again, in seconds | `60`               |
| `ca_file`     | The path of a file of certificates TLS is verified with  | OpenSSL's own certificates             |
| `ca_path`     | The path of a directory of certificates TLS is verified with | OpenSSL's own certificates         |
| `cert_store`  | An `OpenSSL::X509::Store` TLS is verified with           | OpenSSL's own certificates             |
| `client_cert` | The certificate presented to a host that asks for one    | `nil`                                  |
| `client_key`  | The private key of `client_cert`                         | `nil`                                  |

HTTP basic authentication takes precedence over trusted publishing, which takes precedence over the API key, and a
one-time passcode is sent alongside whichever of them is used.

When no key is configured, the API key is resolved for the host it is sent to, as `gem push --host` resolves it: a
client built for another host, and a request made to one with `host:`, use the key `gem signin --host` stored for that
host. A key you configure yourself, and a username and password, are sent wherever the client sends a request, as
`gem push --key` is.

A host nothing is stored for is sent no key at all, so that the key RubyGems.org issued you is not sent to a host it
was not issued for. This is the one place the library resolves a key differently than `gem push --host`, which falls
back to the RubyGems.org key for such a host; store a key for the host with `gem signin --host`, or configure one,
to authenticate there.

An `id_token` is the exception among configured credentials: the API key it is exchanged for is issued by the host
the exchange was made with, for the audience the token names, so a request to another host resolves the key stored
for that host rather than carrying the exchanged one there. Assigning `host` exchanges the token again, for the host
the client is pointed at.

```ruby
# Uses the key stored for gems.example.com, not the RubyGems.org key.
Gems.push 'gemcutter-0.2.1.gem', host: 'https://gems.example.com'
```

Proxies are read from the `http_proxy`, `https_proxy`, and `no_proxy` environment variables unless `proxy_url` is set.
An `https://` proxy is connected to over TLS.

TLS certificates are verified, and there is no option to turn that off. A host whose certificate Ruby's OpenSSL does
not already trust, such as a private gem server with one of its own, is reached by naming that certificate rather than
by skipping the check. `ca_file` and `ca_path` add to the certificates OpenSSL trusts; a `cert_store` of your own
replaces them. A host that asks the client for a certificate is given `client_cert` and `client_key`:

```ruby
# Trust the certificate of a private gem server.
Gems::Client.new(host: 'https://gems.example.com', ca_file: '/etc/ssl/certs/internal.pem')

# Present a client certificate to a host behind mutual TLS.
Gems.configure do |config|
  config.client_cert = OpenSSL::X509::Certificate.new(File.read('client.pem'))
  config.client_key = OpenSSL::PKey::RSA.new(File.read('client.key'))
end
```

A `ca_file` or `ca_path` that names nothing raises `ArgumentError` where it is assigned, as an invalid `host` does,
rather than failing as a TLS error on the next request.

A request is sent on the connection the last request to the same host left open, so that a series of requests does not
open a connection each. `keep_alive_timeout` sets how long an idle connection is kept open, and `0` closes every
connection once its request is done. A request that acts on a gem, such as `push` or `yank`, is sent on a connection
of its own, since a connection the server closed while it was idle cannot be retried for it. `close` closes the connections a
client keeps open; they are opened again as they are needed, so requests can still be made afterwards. A process
forked from one that left a connection open, such as a worker of a server that preloads the application, opens one of
its own rather than sharing the socket of the process it was forked from. A client
built with a block is closed once the block returns or raises, as `Net::HTTP.start` closes the connection it opened:

```ruby
Gems.client.close

Gems::Client.new { |client| client.versions 'rails' }  # closed once the block is done with it
```

Debug output is redacted before it reaches the IO `debug_output` is set to, so that it can be kept in a log: the
`Authorization` and `OTP` headers of every request, the `Proxy-Authorization` header the requests sent through a
proxy carry, the ID token of a trusted publishing token exchange, the API key
`update_api_key` sends, and the API key an API key or token exchange response returns are written as `[REDACTED]`.
Everything else Net::HTTP writes, including the rest of the headers, is left as it is. A client with a debug output
asks for its responses uncompressed, since a compressed body would be written as bytes no credential could be found in,
and a body read from the socket in parts, or sent in chunks, is written as one line once the response is done, so that
a credential split between them is redacted whole.

## Retries

RubyGems.org answers a request it rate limited with 429 Too Many Requests and a `Retry-After` header saying how long
to wait. A request is waited for and sent again twice by default, and `max_retries` sets how many times:

```ruby
Gems.max_retries = 3  # send a request again up to three times
Gems.max_retries = 0  # raise instead of waiting
Gems.rubygem 'rails'
```

A 429 is retried for every request, `push` and `yank` included: RubyGems.org rate limits a request before it reaches
the endpoint, so the endpoint never saw the attempt that was turned away.

A 502 Bad Gateway, a 503 Service Unavailable, a 504 Gateway Timeout, and a `Gems::NetworkError` are retried for a
request that only reads, such as `rubygem` or `versions`, and not for one that acts on a gem, such as `push`, `yank`,
or `remove_owner`. Each of them can be answered after the origin acted on the request: a 502 or 504 comes from a
gateway that read no answer from the origin behind it, a 503 from a CDN that gave up waiting on an origin still at
work, and a read that timed out from a request that arrived. A yank sent again after the origin yanked the version
answers with the error of the version that is already gone, which would be raised in place of the success the call
was owed.

When the retries run out, the response raises the `Gems::HTTPError` of its status and a network failure is raised as
it was. Net::HTTP's own retry of a request whose connection failed is turned off, so `max_retries` is every time a
request is sent again, and a request that times out reading its response waits `read_timeout` once for each attempt
rather than twice.

The trusted publishing token exchange is the exception to all of this: a 429, 502, 503, or 504 answers the exchange
with no key, and an exchange lost to the network may have been issued one whose answer went missing, but an exchange
sent again for any of them either is issued a key or answers that the token is spent, where the publish would have
failed either way, so it is sent again although it is a POST. The wait is the one
`Retry-After` asks for, and doubles from one second up to `max_retry_delay` when the response does not carry the
header, which is the wait after a network failure too, since a request that never arrived has no response to read a
wait from. A wait the library chose for itself is jittered down by up to half, so that the clients a server turned
away at the same moment do not all send their requests again at the same instant; a wait `Retry-After` asked for is
taken as it is, since the server named the moment it is ready. A response asking to wait longer than `max_retry_delay` raises instead, so that a server cannot pause your
program for as long as it likes. `HTTPError#retry_after` reads the header yourself when you would rather handle it in
your own code.

## Thread safety

`Gems.client` is built under a lock, so the methods of the `Gems` module can be called from many threads at once and
share one client between them. That client's connections are pooled per host, and a connection is used by one
request at a time, so concurrent requests neither wait for one another nor share a socket. A trusted publishing ID
token is exchanged for an API key once, however many threads ask for it at the same time.

What is not synchronized is changing things while requests are in flight. The global configuration is meant to be
set up once, before the threads that use it start:

```ruby
Gems.configure do |config|       # at boot
  config.key = ENV.fetch('GEM_HOST_API_KEY')
  config.max_retries = 3
end

threads = 10.times.map { |i| Thread.new { Gems.search('cucumber', page: i + 1) } }
threads.each(&:join)
```

Assigning to `Gems.key`, `Gems.otp`, or another credential afterwards applies it to the shared client, and assigning
to `Gems.host` or `Gems.id_token` builds that client again; either way, a request another thread is making at that
moment carries the credentials it started with. A `Gems::Client` of your own is the same: it is safe to make requests
with from several threads, and its `key=`, `host=`, and `otp=` writers are meant for the thread that owns it rather
than for one racing a request. Give each thread a client of its own when they need different credentials.

## Errors

All errors inherit from `Gems::Error`. HTTP errors are `Gems::HTTPError` subclasses that expose the `response` and
integer status `code`, with specific classes such as `Gems::NotFound`, `Gems::Unauthorized`, and `Gems::Forbidden`, and
`Gems::ClientError` or `Gems::ServerError` for any other 4xx or 5xx status. The message of an error is the response
body, or the status message when the body is empty or an HTML page, such as the error page of a CDN. When a 429 or
503 response carries a `Retry-After` header, `retry_after` reads it as the seconds to wait.
Network failures raise `Gems::NetworkError`, whose `cause` is the `SystemCallError` (an `Errno`), `IOError` (such as
`EOFError`), `SocketError`, `Timeout::Error`, `OpenSSL::SSL::SSLError`, `Zlib::Error`, `Net::HTTPBadResponse`, or
`Net::ProtocolError` underneath, so a timeout worth retrying can be told from a refused connection that is not;
`Gems::NetworkError::WRAPPED` is the list. Redirect loops
raise `Gems::TooManyRedirects`, and a successful response
that cannot be read raises `Gems::InvalidResponse`: one whose body is not JSON, such as the page of a proxy or captive
portal, one whose JSON lacks a field the library reads, or one with a timestamp that cannot be parsed. Asking for the
latest version of a gem that has none, directly or by omitting the version from `yank` or `downloads`, raises
`Gems::NoLatestVersion`.

Invalid arguments raise `ArgumentError` rather than a `Gems::Error`: a `host` or `proxy_url` that is not an HTTP or
HTTPS URL, a raw request path that is a URL of another scheme, host, or port, which would otherwise carry the
credentials resolved for the client's host to the host it names, a raw request path that climbs out of the prefix
its host carries, such as `../..` for a host of `https://gems.example.com/rubygems`, an API key scope the RubyGems API does not
define, which would otherwise be ignored by the server and leave the key scoped differently than it was meant to be,
a reverse dependency type other than `development` or `runtime`, which the endpoint answers with every reverse
dependency for rather than refusing, and an owner role other than `owner` or `maintainer`.

The settings that are numbers are checked where they are assigned too: `open_timeout`, `read_timeout`,
`write_timeout`, `keep_alive_timeout`, and `max_retry_delay` take a number of zero or more seconds, and
`max_redirects` and `max_retries` take a whole number of zero or more times. Anything else raises `ArgumentError`
there, rather than waiting for a negative number of seconds or comparing a count with a String on the next
request, and the setting is left as it was.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake` to run the tests,
linters, mutation tests, type checker, and documentation checks. Coverage, mutation testing, and type checking are
skipped on JRuby. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Supported Ruby Versions
This library aims to support and is [tested against][gh-actions] the following Ruby
implementations:

* Ruby 3.4
* Ruby 4.0
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
