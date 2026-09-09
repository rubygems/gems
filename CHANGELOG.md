# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
* Add `Connection`, `RequestBuilder`, `RedirectHandler`, and `ResponseParser`, with one authenticator class per authentication method, behind the existing client interface
* Add `OtpAuthenticator` and an `otp` option for multi-factor authentication
* Add `TrustedPublisherAuthenticator`, an `id_token` option, and `exchange_trusted_publisher_token` for trusted publishing
* Add `create_api_key` and `update_api_key` for the current API key endpoints
* Add `open_timeout`, `read_timeout`, `write_timeout`, `debug_output`, `proxy_url`, and `max_redirects` options, configurable globally or per client
* Add specific `HTTPError` subclasses such as `NotFound`, `Unauthorized`, and `Forbidden`, exposing the `response` and status `code`
* Add `TooManyRedirects`, raised instead of looping forever on redirects
* Add credential-free `inspect` output for clients and authenticators
* Add `NetworkError`, raised for connection failures, DNS errors, and timeouts instead of the underlying `Errno`, `Net`, `Socket`, and `EOF` errors
* Wrap responses in `Gem`, `Version`, `Dependency`, `Owner`, `WebHook`, `Downloads`, and `ApiKey` objects
* Add `Resource#inspect` summaries such as `#<Gems::Gem name="rails" version="8.1.2">`
* Add RBS signatures

### Changed
* Follow 301, 302, and 303 redirects with GET, keeping the method and body only for 307 and 308
* Take keyword arguments in `Gems::Client.new` and `Gems.new`; unknown options raise `ArgumentError`
* Take keyword arguments in the client's `get`, `post`, `put`, `patch`, and `delete` methods
* Collapse `Gems::V1` and `Gems::V2` into a single `Gems::Client`; `Gems::V2.info` is now `Gems.version`
* Delegate only the API methods from the `Gems` module instead of every client method
* Push to the client's configured host by default
* Read the default API key from `~/.gem/credentials` lazily instead of when the library is required
* Rename `GemError` to `Error` and build HTTP errors from a response rather than a message
* Rename `info` to `gem` and `gems` to `owned_gems`
* Return the version string from `latest_version`
* Split `total_downloads` into `total_downloads` (all gems) and `downloads` (one gem)
* Return a flat list of `WebHook` objects from `web_hooks`, with each hook's `gem_name` set to `*` for hooks on all gems
* Take keyword arguments instead of option hashes in `search`, `yank`, `unyank`, `latest`, `just_updated`, `reverse_dependencies`, `push`, `create_api_key`, and `update_api_key`

### Removed
* Remove `Gems::Version::MAJOR`, `MINOR`, `PATCH`, and `PRE`; `Gems::Version` is now a response object and `Gems::VERSION` remains the library version string
* Remove `dependencies` and `api_key`, whose endpoints have been retired by RubyGems.org; use `create_api_key` instead
* Remove `Gems::AbstractClient`, `Gems::Request`, `Gems::BaseClient`, `Gems.options`, `Gems::Configuration::VALID_OPTIONS_KEYS`, and `Gems::Configuration::DEFAULT_KEY`

### Security
* Verify SSL certificates instead of disabling verification

[unreleased]: https://github.com/rubygems/gems/compare/v2.0.0...HEAD
