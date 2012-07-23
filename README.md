# Gems [![Build Status](https://secure.travis-ci.org/rubygems/gems.png?branch=master)][travis] [![Dependency Status](https://gemnasium.com/rubygems/gems.png?travis)][gemnasium]
Ruby wrapper for the RubyGems.org API.

[travis]: http://travis-ci.org/rubygems/gems
[gemnasium]: https://gemnasium.com/rubygems/gems

## Installation
    gem install gems

## Documentation
[http://rdoc.info/gems/gems](http://rdoc.info/gems/gems)

# Usage Examples
    require 'rubygems'
    require 'gems'

    # Return some basic information about rails.
    Gems.info 'rails'

    # Return an array of active gems that match the query.
    Gems.search 'cucumber'

    # Return all gems that you own.
    Gems.gems

    # Return all gems owned by Erik Michaels-Ober.
    Gems.gems("sferik")

    # Submit a gem to RubyGems.org.
    Gems.push File.new 'gemcutter-0.2.1.gem'

    # Remove a gem from RubyGems.org's index.
    # Defaults to the latest version if no version is specified.
    Gems.yank 'bills', '0.0.1'

    # Update a previously yanked gem back into RubyGems.org's index.
    # Defaults to the latest version if no version is specified.
    Gems.unyank 'bills', '0.0.1'

    # Return an array of version details for coulda.
    Gems.versions 'coulda'

    # Return the total number of downloads for rails_admin 0.0.1.
    # (Defaults to the latest version if no version is specified.)
    Gems.total_downloads 'rails_admin', '0.0.1'

    # Returns an array containing the top 50 downloaded gem versions for today.
    Gems.most_downloaded_today

    # Returns an array containing the top 50 downloaded gem versions of all time.
    Gems.most_downloaded

    # Return the total number of downloads by day for rails_admin 0.0.1.
    # (Defaults to the latest version if no version is specified.)
    Gems.downloads 'rails_admin', '0.0.1'

    # Return the number of downloads by day for coulda 0.6.3 for the past 90 days.
    # (Defaults to the latest version if no version is specified.)
    Gems.downloads 'coulda', '0.6.3'

    # Return the number of downloads by day for coulda 0.6.3 for the past year.
    Gems.downloads 'coulda', '0.6.3', Date.today - 365, Date.today

    # View all owners of a gem that you own.
    Gems.owners 'gemcutter'

    # Add an owner to a RubyGem you own, giving that user permission to manage it.
    Gems.add_owner 'josh@technicalpickles.com', 'gemcutter'

    # Remove a user's permission to manage a RubyGem you own.
    Gems.remove_owner 'josh@technicalpickles.com', 'gemcutter'

    # Return all the webhooks registered under your account.
    Gems.web_hooks

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

    # Retrieve your API key using HTTP basic authentication.
    Gems.configure do |config|
      config.username = 'nick@gemcutter.org'
      config.password = 'schwwwwing'
    end
    Gems.api_key

    # Return an array of gem dependency details for all versions of all the given gems.
    Gems.dependencies ['rails', 'thor']

    # The following methods require authentication.
    # By default, we load your API key from ~/.gem/credentails
    # You can override this default by specifying a custom API key.
    Gems.configure do |config|
      config.key '701243f217cdf23b1370c7b66b65ca97'
    end

## Contributing
In the spirit of [free software](http://www.fsf.org/licensing/essays/free-sw.html), **everyone** is encouraged to help improve this project.

Here are some ways *you* can contribute:

* by using alpha, beta, and prerelease versions
* by reporting bugs
* by suggesting new features
* by writing or editing documentation
* by writing specifications
* by writing code (**no patch is too small**: fix typos, add comments, clean up
  inconsistent whitespace)
* by refactoring code
* by closing [issues](https://github.com/rubygems/gems/issues)
* by reviewing patches

## Submitting an Issue
We use the [GitHub issue tracker](https://github.com/rubygems/gems/issues) to
track bugs and features. Before submitting a bug report or feature request,
check to make sure it hasn't already been submitted. When submitting a bug
report, please include a [Gist](https://gist.github.com/) that includes a stack
trace and any details that may be necessary to reproduce the bug, including
your gem version, Ruby version, and operating system. Ideally, a bug report
should include a pull request with failing specs.

## Submitting a Pull Request
1. [Fork the repository.][fork]
2. [Create a topic branch.][branch]
3. Add specs for your unimplemented feature or bug fix.
4. Run `bundle exec rake spec`. If your specs pass, return to step 3.
5. Implement your feature or bug fix.
6. Run `bundle exec rake spec`. If your specs fail, return to step 5.
7. Run `open coverage/index.html`. If your changes are not completely covered
   by your tests, return to step 3.
8. Add documentation for your feature or bug fix.
9. Run `bundle exec rake doc:yard`. If your changes are not 100% documented, go
   back to step 8.
10. Add, commit, and push your changes.
11. [Submit a pull request.][pr]

[fork]: http://help.github.com/fork-a-repo/
[branch]: http://learn.github.com/p/branching.html
[pr]: http://help.github.com/send-pull-requests/

## Supported Ruby Versions
This library aims to support and is [tested against][travis] the following Ruby
implementations:

* Ruby 1.8.7
* Ruby 1.9.2
* Ruby 1.9.3
* [JRuby][]
* [Rubinius][]

[jruby]: http://www.jruby.org/
[rubinius]: http://rubini.us/

If something doesn't work on one of these interpreters, it should be considered
a bug.

This library may inadvertently work (or seem to work) on other Ruby
implementations, however support will only be provided for the versions listed
above.

If you would like this library to support another Ruby version, you may
volunteer to be a maintainer. Being a maintainer entails making sure all tests
run and pass on that implementation. When something breaks on your
implementation, you will be personally responsible for providing patches in a
timely fashion. If critical issues for a particular implementation exist at the
time of a major release, support for that Ruby version may be dropped.

## Copyright
Copyright (c) 2011 Erik Michaels-Ober. See [LICENSE][] for details.

[license]: https://github.com/rubygems/gems/blob/master/LICENSE.md
