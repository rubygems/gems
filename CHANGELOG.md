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
* Add RBS signatures

### Changed
* Follow 301, 302, and 303 redirects with GET, keeping the method and body only for 307 and 308

### Deprecated
* Deprecate `api_key`, whose endpoint RubyGems.org has retired; use `create_api_key` instead

### Security
* Verify SSL certificates instead of disabling verification

[unreleased]: https://github.com/rubygems/gems/compare/v2.0.0...HEAD
