# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
* Add `Connection`, `RequestBuilder`, `RedirectHandler`, and `ResponseParser`, with one authenticator class per authentication method, behind the existing client interface; `RequestBuilder`, `RedirectHandler`, and `ResponseParser` are private API, which can change within 3.x, the authenticators are read-only, and the constants that map statuses, methods, and headers are private
* Add `OTPAuthenticator` and an `otp` option for multi-factor authentication
* Add `TrustedPublisherAuthenticator`, an `id_token` option, and `exchange_trusted_publisher_token` for trusted publishing
* Add `create_api_key` and `update_api_key` for the current API key endpoints
* Add `autocomplete` for gem name suggestions
* Add a `platform` option to `version` and to `downloads`
* Add `contents` for the file checksums of a version
* Add `attestations` for the sigstore attestations of a version
* Add `timeframe_versions` for the versions created in a timeframe
* Add a `role` option to `add_owner` and `update_owner` for changing an owner's role
* Add `profile` and `me` for user information
* Add `expires_at`, `rubygem_name`, and `mfa` options to `create_api_key`
* Add `open_timeout`, `read_timeout`, `write_timeout`, `debug_output`, `proxy_url`, and `max_redirects` options, configurable globally or per client; the user and password of a proxy URL are decoded before they are sent to the proxy, and kept out of error messages and `Connection#inspect`, and an `https://` proxy is connected to over TLS
* Add `max_retries` and `max_retry_delay` options, configurable globally or per client, which send a request the server turned away with 429 Too Many Requests, 502 Bad Gateway, 503 Service Unavailable, or 504 Gateway Timeout again after the wait its `Retry-After` header asks for, doubling from one second when the response does not carry one; a request lost to the network is sent again too, after the same wait, since a connection that was refused, reset, or timed out never reached the endpoint; retrying is off by default, only an idempotent request is retried, since a request such as pushing a gem cannot be sent a second time to find out whether the server received the first one, and a response asking to wait longer than `max_retry_delay` raises rather than pausing for as long as the server likes, as does a network failure with no retry left
* Add specific `HTTPError` subclasses such as `NotFound`, `Unauthorized`, and `Forbidden`, exposing the `response` and the status `code` as an Integer; any other 4xx or 5xx status raises `ClientError` or `ServerError`; the message of an error is the response body, or the status message when the body is empty or an HTML page, such as the error page of a CDN; `retry_after` reads the `Retry-After` header of a 429 or 503 response as the seconds to wait, never negative
* Add `TooManyRedirects`, raised instead of looping forever on redirects; a redirect that cannot be followed, such as 304 Not Modified or one whose `Location` is missing, is not a valid URL, or is not an HTTP or HTTPS URL, raises the `HTTPError` of its status
* Add `InvalidResponse`, raised with the `body` when a successful response is not JSON, such as the page of a proxy or captive portal, instead of `JSON::ParserError`; it is also raised, instead of `KeyError` or `ArgumentError`, when the JSON lacks a field the library reads, such as the `version` of `latest_version` or the key of an API key, or holds a timestamp that cannot be parsed
* Add `NoLatestVersion`, raised by `latest_version`, and by `yank`, `unyank`, and `downloads` without a version, when a gem has no published version
* Add credential-free `inspect` output for clients and authenticators
* Add `NetworkError`, raised for connection failures, DNS errors, timeouts, malformed responses, and bad compressed bodies instead of the underlying `Errno`, `Net`, `Socket`, `EOF`, `Timeout`, `OpenSSL`, and `Zlib` errors
* Wrap responses in `Gem`, `Version`, `Dependency`, `Owner`, `Profile`, `WebHook`, `Downloads`, and `APIKey` objects; `Version#sha` is hex from every endpoint, decoded from the base64 `sha256` of the most downloaded versions; the objects are immutable, with their attributes frozen at every level, and their constructors take string or symbol keys
* Accept those objects wherever a gem name, version number, owner, web hook URL, or API key is expected, including the `key` option; a version given as the gem to `yank`, `unyank`, or `downloads` stands in for the version too
* Accept a path as well as an open file in `push`, for the gem and for its attestations
* Compare resources by identity, so `Gems.gem("rails") == Gems.gem("rails")` regardless of download counts
* Add `Resource#inspect` summaries such as `#<Gems::Gem name="rails" version="8.1.2">`
* Match resources against `case`/`in` patterns by their readers, such as `in {name:, version:}`, with `Resource#deconstruct_keys` and `Resource.attribute_names`
* Add `key_configured?`, and a host argument to `default_key`, for the API key stored for a host other than the configured one
* Add `default_host`, the host `gem push` would use, which reads the `RUBYGEMS_HOST` environment variable when it is called rather than when the library is required
* Reuse the connection a request left open for the next request to the same host, so that a series of requests does not open a connection each; a `keep_alive_timeout` option sets the seconds an idle connection is kept open, which zero turns off, and `Client#close` closes the connections a client keeps open, which are opened again as they are needed
* Add `search_each`, `latest_each`, `just_updated_each`, and `timeframe_versions_each`, which walk the pages of the endpoints that answer one page at a time: each returns an `Enumerator`, requests a page only once the results of the page before it have been enumerated, and stops at the first empty page, so `Gems.search_each("cucumber").first(100)` requests only the pages it needs
* Add RBS signatures, with a manifest naming the standard libraries they refer to

### Changed
See [UPGRADING.md](https://github.com/rubygems/gems/blob/master/UPGRADING.md) for the changes that code written for 2.x needs.

* Follow 301, 302, and 303 redirects with GET, keeping the method and body only for 307 and 308, and follow a redirect to another scheme, host, or port without the API key, basic authentication, or one-time passcode of the request, so that a redirect cannot send them to a host they were not meant for
* Take keyword arguments in `Gems::Client.new` and `Gems.new`; unknown options raise `ArgumentError`
* Take keyword arguments in the client's `get`, `post`, `put`, `patch`, and `delete` methods
* Collapse `Gems::V1` and `Gems::V2` into a single `Gems::Client`; `Gems::V2.info` is now `Gems.version`
* Delegate only the API methods from the `Gems` module, to one client, `Gems.client`, which is built from the global configuration and built again when it changes, rather than every client method to a new client for every call, so that a trusted publishing ID token is exchanged once; the raw request methods are on `Gems.client`
* Push to the client's configured host by default
* Read the default API key from `~/.gem/credentials` lazily instead of when the library is required; assigning `nil` to `key` now disables that fallback without disabling configured basic authentication or trusted publishing
* Resolve the default API key as `gem push` does: the `GEM_HOST_API_KEY` environment variable, else the key `gem signin --host` stored for the configured host, else the RubyGems.org key
* Return `nil` from `default_key`, rather than exiting the process as RubyGems does, when `~/.gem/credentials` does not have the permissions RubyGems requires; RubyGems still reports the problem on standard error
* Rename `GemError` to `Error` and build HTTP errors from a response rather than a message
* Rename `info` to `rubygem` and `gems` to `owned_gems`
* Return the version string from `latest_version`
* Split `total_downloads` into `total_downloads` (all gems) and `downloads` (one gem)
* Return a flat list of `WebHook` objects from `web_hooks`, with each hook's `gem_name` set to `*` for hooks on all gems
* Take keyword arguments instead of option hashes in `search`, `yank`, `unyank`, `latest`, `just_updated`, `reverse_dependencies`, `push`, `create_api_key`, and `update_api_key`
* Resolve the default API key for the host a request is sent to, as `gem push --host` resolves it, so that a client built for another host, and a request made to one with `host:`, send the key `gem signin --host` stored for it rather than the RubyGems.org key; a configured key, basic authentication, and a trusted publishing ID token are sent wherever the client sends a request, as `gem push --key` is
* Exchange a trusted publishing ID token once when requests are made concurrently, since RubyGems.org issues the API key only once per token
* Build the client the module delegates to again only when the configured credentials change, and apply the rest of the configuration — the user agent, the timeouts, the debug output, the proxy, and the maximum redirects — to the client it has, so that changing one of them no longer throws away the API key an ID token was exchanged for; `Gems.reset` forgets the client, and a mutex guards it, so that threads calling it at once build one client
* Inherit the readers a resource declares in its subclasses, so that a subclass of `Gem`, `Version`, or another resource keeps matching patterns, inspecting, and comparing by them
* Raise `InvalidResponse` from `Version#sha`, rather than `ArgumentError` or `NoMethodError`, when the base64 `sha256` of a response cannot be decoded
* Read the `RUBYGEMS_HOST` environment variable when the host is resolved rather than when the library is required, as the API key is read; `Configuration::DEFAULT_HOST` is now the RubyGems.org host, which `default_host` falls back to
* Raise `ArgumentError` for a `host` that is not an HTTP or HTTPS URL, when a client is built and when `host` is assigned, rather than letting `URI::BadURIError` or `URI::InvalidURIError` escape when a request is made; an invalid host leaves the host as it was, as an invalid `proxy_url` does
* Check the `host` and `proxy_url` assigned to the global configuration where they are assigned, as `Client#host=` and `Connection#proxy_url=` check the ones assigned to a client, so that the `ArgumentError` names the assignment that was wrong rather than escaping from the next call that happens to build a client; the host a reset restores is taken as it is, so that a `RUBYGEMS_HOST` that is not a URL is reported when a client is built with it rather than when the library is required
* Close the connections of the client `Gems.reset` forgets, since no request of the module will be sent on them again, as the connections of a client the module replaces are closed
* Build the replacement client before closing the client it replaces, so that a configuration a client cannot be built from leaves the client the module has open rather than closing it on the way to raising
* Count an empty `GEM_HOST_API_KEY` as no key rather than as an empty one, since a continuous integration service sets a variable to the empty string when the secret it was given is not set, and an empty `Authorization` header answers with a puzzling 401 where a request without one answers with the error the endpoint has for an unauthenticated request
* Raise `ArgumentError` for an API key scope the RubyGems API does not define, rather than sending a misspelled scope for the server to ignore and leaving the key scoped differently than it was meant to be

### Removed
* Require Ruby 3.4 or later: Ruby 3.1 and 3.2 have reached end of life, Ruby 3.3 reaches it in March 2027, within the life of 3.x, and Ruby 3.4 bundles the net-http that connects to an HTTPS proxy over TLS
* Remove `Gems::Version::MAJOR`, `MINOR`, `PATCH`, and `PRE`; `Gems::Version` is now a response object and `Gems::VERSION` remains the library version string
* Remove `dependencies` and `api_key`, whose endpoints have been retired by RubyGems.org; use `create_api_key` instead
* Remove `Gems::AbstractClient`, `Gems::Request`, `Gems::BaseClient`, `Gems.options`, `Gems::Configuration::VALID_OPTIONS_KEYS`, and `Gems::Configuration::DEFAULT_KEY`

### Deprecated
* Deprecate `GemError`, kept as a constant alias; use `Error` instead

### Security
* Verify SSL certificates instead of disabling verification
* Redact credentials from `debug_output`, which Net::HTTP would otherwise write in the clear: the `Authorization` and `OTP` headers of every request, the ID token a trusted publishing token exchange sends, the API key `update_api_key` sends as a form field, and the API key an API key or token exchange response returns are written as `[REDACTED]`
* Escape the gem names, user handles, version numbers, and platforms interpolated into request paths, so that a value holding a slash cannot walk out of the endpoint it was meant for and take the credentials of the request with it, and one holding a question mark or a number sign cannot add a query string or truncate the path; a value holding a space or a character outside ASCII is escaped rather than raising `URI::InvalidURIError`
* Resolve the API key stored for the host again when `Client#host=` is assigned, so that a client pointed at another host stops sending the key stored for the host it was built for; a configured key, basic authentication, and a trusted publishing ID token are still sent wherever the client sends a request, as `gem push --key` is

[unreleased]: https://github.com/rubygems/gems/compare/v2.0.0...HEAD
