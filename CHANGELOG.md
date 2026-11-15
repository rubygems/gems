# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/2.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.1] - 2026-11-16

### Security

- Send the API key, and the username and password of a basic auth request such as `api_key`, only to the scheme and host a request was made to, so a redirect to another host or to plain HTTP is followed without them, as is every redirect after it
- Verify TLS certificates, which were not verified before, so a host whose certificate does not verify is refused rather than sent the credentials of a request

## [1.3.1] - 2026-11-16

### Security

- Send the API key, and the username and password of a basic auth request such as `api_key`, only to the scheme and host a request was made to, so a redirect to another host or to plain HTTP is followed without them, as is every redirect after it
- Verify TLS certificates, which were not verified before, so a host whose certificate does not verify is refused rather than sent the credentials of a request

[2.0.1]: https://github.com/rubygems/gems/compare/v2.0.0...v2.0.1
[1.3.1]: https://github.com/rubygems/gems/compare/v1.3.0...v1.3.1
