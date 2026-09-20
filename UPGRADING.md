# Upgrading

## From 2.x to 3.0

Version 3.0 replaces the option hashes, the `V1` and `V2` clients, and the Hash responses of 2.x with keyword
arguments, one `Gems::Client`, and resource objects, and it renames or removes what 2.x had under old names without
deprecating them first. This guide covers what code written for 2.x needs to change. See
[CHANGELOG.md](https://github.com/rubygems/gems/blob/master/CHANGELOG.md) for everything that was added.

### Ruby

Version 3.0 requires Ruby 3.4 or later.

### Clients and configuration

`Gems::Client.new` and `Gems.new` take keyword arguments, and an unknown option raises `ArgumentError`. `Gems::V1`,
`Gems::V2`, `Gems::AbstractClient`, `Gems::Request`, `Gems::BaseClient`, `Gems.options`,
`Gems::Configuration::VALID_OPTIONS_KEYS`, and `Gems::Configuration::DEFAULT_KEY` are gone:

```ruby
# 2.x
client = Gems::Client.new(:key => "rubygems_701243f217cdf23b1370c7b66b65ca97")
Gems::V2.info "rails", "7.0.6"

# 3.0
client = Gems::Client.new(key: "rubygems_701243f217cdf23b1370c7b66b65ca97")
Gems.version "rails", "7.0.6"
```

The `Gems` module delegates the API methods alone to one client, `Gems.client`, which is built from the global
configuration and built again when it changes, where 2.x delegated every client method to a new client for every
call. The raw request methods are on that client:

```ruby
# 2.x
Gems.get "/api/v1/gems/rails.json"

# 3.0
Gems.client.get "/api/v1/gems/rails.json"
```

The API key in `~/.gem/credentials` is read when it is first needed rather than when the library is required, and
assigning `nil` to `key` turns that fallback off, where 2.x fell back to it anyway. The default key is resolved as
`gem push` resolves it: the `GEM_HOST_API_KEY` environment variable comes first, then the key `gem signin --host`
stored for the configured `host`, then the RubyGems.org key, where 2.x read only the RubyGems.org key:

```ruby
# 3.0
Gems.key = nil                  # send requests without an API key
Gems.configure { |config| config.key = nil }
```

The default key is resolved for the host a request is sent to, so a client built for another host, and a request made
to one with `host:`, send the key `gem signin --host` stored for that host rather than the RubyGems.org key, where 2.x
sent the RubyGems.org key wherever `push` was pointed. A key you configure yourself is sent wherever the client sends a
request, as `gem push --key` is:

```ruby
# 3.0
Gems.push "gems-0.0.8.gem", host: "https://gems.example.com"   # uses the key stored for gems.example.com
```

A `host` that is not an HTTP or HTTPS URL raises `ArgumentError` where it is assigned, whether that is `Gems.host`,
a client's `host`, or the `host:` a client is built with, and an invalid `proxy_url` does the same. 2.x let
`URI::BadURIError` or `URI::InvalidURIError` escape when a request was made:

```ruby
# 3.0
Gems.host = "rubygems.org"      # ArgumentError: Invalid host: rubygems.org
```

An empty `GEM_HOST_API_KEY` counts as no key rather than as an empty one, so a continuous integration job whose
secret is not set sends an unauthenticated request instead of an empty `Authorization` header.

The one-time passcode is resolved the way the API key is: until one is assigned, it is the `GEM_HOST_OTP_CODE`
environment variable `gem push` falls back to, and an empty one counts as no passcode. Assigning nil to `otp`, as to
`key`, disables that fallback.

The options `otp`, `id_token`, `open_timeout`, `read_timeout`, `write_timeout`, `debug_output`, `proxy_url`,
`max_redirects`, `max_retries`, and `max_retry_delay` are new, and every option can be set globally or per client.

### Renamed methods

| 2.x | 3.0 |
| --- | --- |
| `Gems.info(name)` | `Gems.rubygem(name)` |
| `Gems::V2.info(name, version)` | `Gems.version(name, version)` |
| `Gems.gems(handle)` | `Gems.owned_gems(handle)` |
| `Gems.total_downloads(name, version)` | `Gems.downloads(name, version)` |
| `Gems::GemError` | `Gems::Error` |

`Gems::GemError` remains as a deprecated alias of `Gems::Error`, and is the only name kept.

### Keyword arguments

The methods that took an option hash take keyword arguments, and the host of `push` is a keyword that defaults to
the client's host rather than to RubyGems.org:

```ruby
# 2.x
Gems.search "cucumber", {:page => 2}
Gems.push File.new("gems-0.0.8.gem"), "https://gems.example.com"
Gems.yank "gems", "0.0.8", {:platform => "java"}

# 3.0
Gems.search "cucumber", page: 2
Gems.push File.new("gems-0.0.8.gem"), host: "https://gems.example.com"
Gems.yank "gems", "0.0.8", platform: "java"
```

`latest`, `just_updated`, `unyank`, `reverse_dependencies`, `create_api_key`, and `update_api_key` changed the same
way.

### Pagination

The endpoints that take a `page` option have an `_each` counterpart that walks the pages, so the loops 2.x needed
are no longer yours to write:

```ruby
# 2.x
page = 1
gems = []
loop do
  results = Gems.search("cucumber", :page => page)
  break if results.empty?
  gems += results
  page += 1
end

# 3.0
gems = Gems.search_each("cucumber").to_a
```

`latest_each`, `just_updated_each`, and `timeframe_versions_each` do the same for their endpoints.

### Return values

The methods that returned parsed JSON return objects: `Gems::Gem`, `Gems::Version`, `Gems::Dependency`,
`Gems::Owner`, `Gems::Profile`, `Gems::WebHook`, `Gems::Downloads`, and `Gems::APIKey`. Each reads its fields with
methods, parses timestamps into `Time` objects, and offers `[]` and `to_h` for the raw response, so code that read
the Hash can keep doing so:

```ruby
# 2.x
Gems.info("rails")["version"]
Gems.versions("rails").map { |version| version["number"] }
Gems.owners("rails").map { |owner| owner["handle"] }

# 3.0
Gems.rubygem("rails").version
Gems.versions("rails").map(&:number)
Gems.owners("rails").map(&:handle)
Gems.rubygem("rails")["version"] # still works
```

The attributes are frozen, at every level, so an object is an immutable value and `to_h` returns a frozen Hash. Code
that changed the Hash a 2.x method returned needs to copy it first:

```ruby
# 2.x
gem = Gems.info("rails")
gem["downloads"] += 1

# 3.0
gem = Gems.rubygem("rails").to_h.dup
gem["downloads"] += 1
```

Some return values changed shape:

```ruby
# 2.x
Gems.latest_version("rails")                # => {"version" => "8.1.2"}
Gems.total_downloads                        # => {:total => 123}
Gems.total_downloads("rails", "8.1.2")      # => {:version_downloads => 1, :total_downloads => 2}
Gems.most_downloaded                        # => [[{"full_name" => "rails-8.1.2", ...}, 123], ...]
Gems.web_hooks                              # => {"all gems" => [{"url" => ...}], "rails" => [...]}

# 3.0
Gems.latest_version("rails")                # => "8.1.2"
Gems.total_downloads                        # => 123
Gems.downloads("rails", "8.1.2")            # => #<Gems::Downloads total=2 version_downloads=1>
Gems.most_downloaded                        # => [#<Gems::Version name="rails" number="8.1.2">, ...], with downloads_count
Gems.web_hooks                              # => [#<Gems::WebHook gem_name="*" url=...>, ...]
```

A web hook on all gems has a `gem_name` of `"*"`. Objects are accepted wherever their identifier is expected, so
`Gems.versions(gem)`, `Gems.remove_owner(gem, owner)`, and `Gems.key = api_key` work, and they compare by identity,
so `Gems.rubygem("rails") == Gems.rubygem("rails")` even when the download counts have changed in between.

### Errors

Every error is a `Gems::Error`. `Gems::NotFound` is one of the `Gems::HTTPError` subclasses, which expose the
`response` and the status `code` as an Integer, with `Gems::ClientError` or `Gems::ServerError` for any 4xx or 5xx
status without a class of its own:

```ruby
# 2.x
rescue Gems::NotFound, Gems::GemError

# 3.0
rescue Gems::NotFound   # a 404
rescue Gems::HTTPError  # any error status; error.code and error.response say which
rescue Gems::Error      # everything the library raises
```

Failures that 2.x let through as other exceptions are `Gems::Error` subclasses now:

* Connection failures, DNS errors, timeouts, and SSL errors raise `Gems::NetworkError` rather than the underlying
  `Errno`, `Net`, `Socket`, `OpenSSL`, and `Timeout` errors.
* A successful response whose body is not JSON raises `Gems::InvalidResponse` rather than `JSON::ParserError`, and
  `rubygem` and `version` raise it rather than return `{}`. A response whose JSON lacks a field the library reads,
  such as the `version` of `latest_version` or the key of an API key, raises it rather than `KeyError`, and a
  timestamp that cannot be parsed raises it rather than `ArgumentError`.
* Asking for the latest version of a gem that has none, directly or by omitting the version from `yank`, `unyank`,
  or `downloads`, raises `Gems::NoLatestVersion` rather than sending `"unknown"` as the version.
* A redirect loop raises `Gems::TooManyRedirects` after `max_redirects` hops rather than recursing forever.

SSL certificates are verified, where 2.x disabled verification. A host with a certificate that Ruby's OpenSSL does
not trust, such as a private gem server with a self-signed certificate, raises `Gems::NetworkError` until the
certificate is trusted. A redirect to another scheme, host, or port is followed without the credentials of the
request, where 2.x sent the API key wherever the redirect led.

### Removed methods and constants

`dependencies` and `api_key` are gone, since RubyGems.org retired their endpoints. `create_api_key` replaces
`api_key`:

```ruby
# 2.x
Gems.configure do |config|
  config.username = "nick@gemcutter.org"
  config.password = "schwwwwing"
end
Gems.api_key

# 3.0
Gems.configure do |config|
  config.username = "nick@gemcutter.org"
  config.password = "schwwwwing"
end
Gems.create_api_key("ci-push", push_rubygem: true).key
```

`create_api_key` and `update_api_key` raise `ArgumentError` for a scope the RubyGems API does not define, where 2.x
sent whatever it was given for the server to ignore, leaving the key scoped differently than it was meant to be.

`Gems::Version::MAJOR`, `MINOR`, `PATCH`, and `PRE` are gone. `Gems::VERSION` is the library's version string, and
`Gems::Version` is the object returned for a version of a gem.

`Gems::Configuration::DEFAULT_HOST` is the RubyGems.org host, where 2.x froze the `RUBYGEMS_HOST` environment
variable into it when the library was required. The environment variable is still the default host, read by
`Gems.default_host` when the host is resolved, as the API key is read:

```ruby
# 2.x
Gems::Configuration::DEFAULT_HOST # => ENV["RUBYGEMS_HOST"], read when the library was required

# 3.0
Gems.default_host                 # => ENV["RUBYGEMS_HOST"], read now
Gems.host                         # => the same, until another host is configured
```

### Internals

Everything documented as `@api private` can change within 3.x, and is hidden from the generated documentation:
`Gems::RequestBuilder`, `Gems::RedirectHandler`, `Gems::ResponseParser`, `Gems::RetryHandler`,
`Gems::ConnectionPool`, and the mixins beneath them, such as `Gems::Idempotence`, `Gems::Identifiers`,
`Gems::JSONParsing`, `Gems::Pagination`, `Gems::PathEscaping`, `Gems::RedactedOutput`, `Gems::RetryAfter`, and
`Gems::URLValidation`. Configure them through the options of `Gems::Client`, such as `user_agent`, `max_redirects`,
and `max_retries`. The authenticators are read-only; change a credential with the setters of `Gems::Client` or the
`Gems` module, which build the authenticator again.
