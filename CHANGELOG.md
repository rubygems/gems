# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
* Add `Connection`, `RequestBuilder`, `RedirectHandler`, and `ResponseParser`, with one authenticator class per authentication method, behind the existing client interface; `RequestBuilder`, `RedirectHandler`, and `ResponseParser` are private API, which can change within 3.x, the authenticators are read-only, and the constants that map statuses, methods, and headers are private
* Add `OtpAuthenticator` and an `otp` option for multi-factor authentication
* Add `TrustedPublisherAuthenticator`, an `id_token` option, and `exchange_trusted_publisher_token` for trusted publishing
* Add `create_api_key` and `update_api_key` for the current API key endpoints
* Add `autocomplete` for gem name suggestions
* Add a `platform` option to `version`
* Add `contents` for the file checksums of a version
* Add `attestations` for the sigstore attestations of a version
* Add `timeframe_versions` for the versions created in a timeframe
* Add a `role` option to `add_owner` and `update_owner` for changing an owner's role
* Add `profile` and `me` for user information
* Add `expires_at`, `rubygem_name`, and `mfa` options to `create_api_key`
* Add `open_timeout`, `read_timeout`, `write_timeout`, `debug_output`, `proxy_url`, and `max_redirects` options, configurable globally or per client; the user and password of a proxy URL are decoded before they are sent to the proxy, and kept out of error messages and `Connection#inspect`, and an `https://` proxy is connected to over TLS
* Add specific `HTTPError` subclasses such as `NotFound`, `Unauthorized`, and `Forbidden`, exposing the `response` and the status `code` as an Integer; any other 4xx or 5xx status raises `ClientError` or `ServerError`; the message of an error is the response body, or the status message when the body is empty or an HTML page, such as the error page of a CDN; `retry_after` reads the `Retry-After` header of a 429 or 503 response as the seconds to wait
* Add `TooManyRedirects`, raised instead of looping forever on redirects; a redirect that cannot be followed, such as 304 Not Modified or one whose `Location` is missing, is not a valid URL, or is not an HTTP or HTTPS URL, raises the `HTTPError` of its status
* Add `InvalidResponse`, raised with the `body` when a successful response is not JSON, such as the page of a proxy or captive portal, instead of `JSON::ParserError`; it is also raised, instead of `KeyError` or `ArgumentError`, when the JSON lacks a field the library reads, such as the `version` of `latest_version` or the key of an API key, or holds a timestamp that cannot be parsed
* Add `NoLatestVersion`, raised by `latest_version`, and by `yank`, `unyank`, and `downloads` without a version, when a gem has no published version
* Add credential-free `inspect` output for clients and authenticators
* Add `NetworkError`, raised for connection failures, DNS errors, timeouts, malformed responses, and bad compressed bodies instead of the underlying `Errno`, `Net`, `Socket`, `EOF`, `Timeout`, `OpenSSL`, and `Zlib` errors
* Wrap responses in `Gem`, `Version`, `Dependency`, `Owner`, `Profile`, `WebHook`, `Downloads`, and `ApiKey` objects; `Version#sha` is hex from every endpoint, decoded from the base64 `sha256` of the most downloaded versions
* Accept those objects wherever a gem name, version number, owner, web hook URL, or API key is expected, including the `key` option; a version given as the gem to `yank`, `unyank`, or `downloads` stands in for the version too
* Accept a path as well as an open file in `push`, for the gem and for its attestations
* Compare resources by identity, so `Gems.gem("rails") == Gems.gem("rails")` regardless of download counts
* Add `Resource#inspect` summaries such as `#<Gems::Gem name="rails" version="8.1.2">`
* Match resources against `case`/`in` patterns by their readers, such as `in {name:, version:}`, with `Resource#deconstruct_keys` and `Resource.attribute_names`
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
* Rename `GemError` to `Error` and build HTTP errors from a response rather than a message
* Rename `info` to `rubygem` and `gems` to `owned_gems`
* Return the version string from `latest_version`
* Split `total_downloads` into `total_downloads` (all gems) and `downloads` (one gem)
* Return a flat list of `WebHook` objects from `web_hooks`, with each hook's `gem_name` set to `*` for hooks on all gems
* Take keyword arguments instead of option hashes in `search`, `yank`, `unyank`, `latest`, `just_updated`, `reverse_dependencies`, `push`, `create_api_key`, and `update_api_key`

### Removed
* Require Ruby 3.4 or later: Ruby 3.1 and 3.2 have reached end of life, Ruby 3.3 reaches it in March 2027, within the life of 3.x, and Ruby 3.4 bundles the net-http that connects to an HTTPS proxy over TLS
* Remove `Gems::Version::MAJOR`, `MINOR`, `PATCH`, and `PRE`; `Gems::Version` is now a response object and `Gems::VERSION` remains the library version string
* Remove `dependencies` and `api_key`, whose endpoints have been retired by RubyGems.org; use `create_api_key` instead
* Remove `Gems::AbstractClient`, `Gems::Request`, `Gems::BaseClient`, `Gems.options`, `Gems::Configuration::VALID_OPTIONS_KEYS`, and `Gems::Configuration::DEFAULT_KEY`

### Deprecated
* Deprecate `GemError`, kept as a constant alias; use `Error` instead

### Security
* Verify SSL certificates instead of disabling verification

[unreleased]: https://github.com/rubygems/gems/compare/v2.0.0...HEAD
