# Security Policy

## Supported versions

Security fixes are released for the most recent minor release of the current major series. Older series are not
patched, so upgrading is the way to receive a fix.

| Version | Supported |
| ------- | --------- |
| 3.x     | Yes       |
| 2.x     | No        |
| 1.x     | No        |

## Reporting a vulnerability

Please do not report security vulnerabilities through public GitHub issues, pull requests, or discussions.

This library is maintained by the RubyGems team, so report vulnerabilities through either of the channels in the
[RubyGems security policy](https://rubygems.org/pages/security):

* Email [security@rubygems.org](mailto:security@rubygems.org)
* Submit a report to [hackerone.com/rubygems](https://hackerone.com/rubygems)

Include the version of the gem, the Ruby version, and the steps to reproduce the problem. RubyGems no longer offers
monetary rewards for bug bounty reports, but any effort to discover and disclose vulnerabilities responsibly is
appreciated.

## What this library handles

This library sends credentials to RubyGems.org and to other RubyGems-compatible hosts: API keys, HTTP basic
authentication credentials, one-time passcodes, and the OIDC ID tokens of trusted publishing. Reports about the way
those are stored, sent, logged, or resolved are particularly welcome. It already takes these precautions, so a way
around one of them is a vulnerability rather than a feature request:

* Credentials are redacted from `debug_output`, which Net::HTTP would otherwise write in the clear, including the
  `Proxy-Authorization` header of a request sent through a proxy and of the CONNECT that opens a TLS connection
  through one.
* A redirect to another scheme, host, or port is followed without the credentials or the caller's headers, and
  one that would send the body of the request again is not followed at all, since a body carries a credential of
  its own for the endpoints that take an API key or an ID token as a field.
* `inspect` output for clients and authenticators never includes credentials.
* The values interpolated into request paths are escaped, so one holding a slash cannot walk out of the endpoint it
  was meant for and take the credentials of the request with it.
* A host nothing is stored for is sent no API key, rather than the RubyGems.org key that `gem push --host` falls
  back to for it, so that a key is sent only to the host it was issued by. The API key a trusted publishing ID token
  is exchanged for is sent only to the host that exchanged it, rather than to whichever host a request names.
* TLS certificates are verified, and no option turns that off: a host whose certificate OpenSSL does not already
  trust is reached by naming that certificate with `ca_file`, `ca_path`, or `cert_store`.
