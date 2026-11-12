# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/2.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
* Redact the credential values a request carries from `debug_output` wherever they appear, not only in the forms
  the library itself writes them in, so that a host which echoes a credential back in a response — under a name of
  its own, or in an encoding of its own — does not carry it past the redaction into the IO

## [3.0.0] - 2026-09-26

See [UPGRADING.md](https://github.com/rubygems/gems/blob/master/UPGRADING.md) for the changes code written for 2.x
needs, and the [README](https://github.com/rubygems/gems/blob/master/README.md) for how each feature behaves.

### Added

- Add `autocomplete`, `contents`, `attestations`, `timeframe_versions`, `reverse_dependency_versions`, `profile`, `me`, `webauthn_verification`, and `webauthn_verification_status` for endpoints 2.x had no method for
- Add `create_api_key` and `update_api_key`, which take the scopes to grant as `scopes: %i[push_rubygem]` and check them against `Gems::APIKey::SCOPES`
- Add trusted publishing: an `id_token` option, `exchange_trusted_publisher_token`, and `trusted_publishers`, `trusted_publisher`, `add_trusted_publisher`, and `remove_trusted_publisher`
- Add `api_key_roles`, `api_key_role`, `assume_api_key_role`, `oidc_providers`, `oidc_provider`, `oidc_id_tokens`, and `oidc_id_token` for OIDC API key roles
- Add an `otp` option for multi-factor authentication, which falls back to `GEM_HOST_OTP_CODE` as `gem push` does
- Add a `page` option to `autocomplete`, a `platform` option to `version`, `contents`, `attestations`, and `downloads`, a `ruby_abi` option to `version`, `contents`, and `yank`, and a `role` option to `add_owner` and `update_owner`
- Add `search_each` and `timeframe_versions_each`, which walk the pages of those endpoints lazily
- Wrap responses in `Gem`, `Version`, `Dependency`, `Owner`, `Profile`, `WebHook`, `Downloads`, `APIKey`, `APIKeyRole`, `OIDCProvider`, `OIDCIDToken`, `TrustedPublisher`, `WebAuthnVerification`, and `WebAuthnVerificationStatus` objects, which are immutable, compare by identity, match `case`/`in` patterns, inspect as short summaries, and keep `[]` and `to_h` for the raw response
- Order gems and versions with `<=>` as RubyGems orders version numbers, so `"7.0.10"` sorts after `"7.0.9"`
- Compare and order gems and versions by the platform and Ruby ABI of their build, and show both in `inspect` where they tell one build from another
- Accept those objects wherever a gem name, version, owner, web hook URL, or API key is expected; a gem or version given as the gem acts on the version and build it names
- Add `open_timeout`, `read_timeout`, `write_timeout`, `keep_alive_timeout`, `debug_output`, `proxy_url`, and `max_redirects` options, set globally or per client
- Add `max_retries` and `max_retry_delay` options: a 429, 502, 503, or 504, or a request the network lost, is sent again twice by default, honoring `Retry-After`, for the requests it is safe to send again
- Add `ca_file`, `ca_path`, `cert_store`, `client_cert`, and `client_key` options, for hosts with certificates of their own and for mutual TLS
- Reuse connections across requests to the same host; `Client#close` closes them, and a client built with a block closes them when the block returns
- Add a `headers` option to the client's raw request methods
- Add `key_configured?`, `otp_configured?`, `default_host`, and `default_otp`, and a host argument to `default_key`
- Add `HTTPError` subclasses, such as `NotFound` and `TooManyRequests`, with `ClientError` and `ServerError` for the other statuses, which expose `response`, `code`, and `retry_after`
- Add `NetworkError`, `InvalidResponse`, `TooManyRedirects`, and `NoLatestVersion`, raised in place of the standard library errors 2.x let through
- Add RBS signatures, with a manifest naming the standard libraries they refer to

### Changed

- **Breaking:** Collapse `Gems::V1` and `Gems::V2` into one `Gems::Client`
- **Breaking:** Take keyword arguments in `Gems::Client.new`, `Gems.new`, the raw request methods, `search`, `yank`, `reverse_dependencies`, and `push`; unknown options raise `ArgumentError`
- **Breaking:** Rename `info` to `rubygem`, `Gems::V2.info` to `version`, `gems` to `owned_gems`, and `GemError` to `Error`
- **Breaking:** Raise `ArgumentError` from `yank` when no version is given, rather than yanking the latest version
- **Breaking:** Split `total_downloads` into `total_downloads` (all gems) and `downloads` (one gem)
- **Breaking:** Return a version string from `latest_version` and a flat list of `WebHook` objects from `web_hooks`
- **Breaking:** Delegate only the API methods from the `Gems` module, to one client, `Gems.client`, which also has the raw request methods
- **Breaking:** Send the API key rather than the username and password to every endpoint but `create_api_key`, `update_api_key`, and `me`, which take only the username and password
- Resolve the default API key as `gem push` does, for the host each request is sent to, and read it and `RUBYGEMS_HOST` when they are needed rather than when the library is required
- Return `nil` from `default_key`, rather than exiting the process, when `~/.gem/credentials` has the wrong permissions
- Push to the client's host by default, streaming the gem rather than reading it into memory
- Follow 301, 302, and 303 redirects with GET, and follow a redirect to another host without the credentials or headers of the request
- Raise `ArgumentError` where an invalid host, proxy URL, certificate path, timeout, role, or dependency type is given, rather than when a request is made or the server ignores it
- Name the library and the Ruby it runs on in the default `User-Agent`
- Define `Gems::VERSION` in `gems/library_version`, so the gemspec reads it without loading the library

### Deprecated

- Deprecate `GemError`, kept as an alias of `Error`

### Removed

- **Breaking:** Require Ruby 3.4 or later
- **Breaking:** Remove `dependencies`, `api_key`, and `unyank`, whose endpoints RubyGems.org has retired; `create_api_key` replaces `api_key`
- **Breaking:** Remove the `page` option of `latest` and `just_updated`, whose endpoints answer with the same 50 gems for every page
- **Breaking:** Remove `Gems::Version::MAJOR`, `MINOR`, `PATCH`, and `PRE`; `Gems::Version` is now a response object
- **Breaking:** Remove `Gems::AbstractClient`, `Gems::Request`, `Gems::BaseClient`, `Gems.options`, `Gems::Configuration::VALID_OPTIONS_KEYS`, and `Gems::Configuration::DEFAULT_KEY`

### Security

- Verify TLS certificates, which 2.x did not; there is no option to turn verification off
- Send the RubyGems.org API key to RubyGems.org alone, and no key to a host nothing is stored for
- Redact credentials from `debug_output`, including the API keys responses carry
- Escape the values interpolated into request paths, and refuse a path that leaves the client's host
- Send the name of a pushed gem file rather than its path
- Keep credentials out of the `inspect` output of clients and out of error messages

[Unreleased]: https://github.com/rubygems/gems/compare/v3.0.0...HEAD
[3.0.0]: https://github.com/rubygems/gems/compare/v2.0.0...v3.0.0
