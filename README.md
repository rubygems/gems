Gems
====
Ruby wrapper for the RubyGems.org API.

Installation
------------
    gem install gems

Documentation
-------------
[http://rdoc.info/gems/gems](http://rdoc.info/gems/gems)

Continuous Integration
----------------------
[![Build Status](http://travis-ci.org/sferik/gems.png)](http://travis-ci.org/sferik/gems)

Usage Examples
--------------
    require 'rubygems'
    require 'gems'

    # Returns some basic information about the rails gem
    puts Gems.info 'rails'

    # Returns an array of active gems that match the query
    puts Gems.search 'cucumber'

    # Returns an array of gem version details
    puts Gems.versions 'coulda'

    # Returns the number of downloads by day for a particular gem version
    puts Gems.downloads 'coulda', '0.6.3'

    # Returns an array of gem dependency details for all versions of given gems
    puts Gems.dependencies ['rails', 'thor']

    # Retrieve your API key using HTTP basic authentication
    Gems.configure do |config|
      config.username = 'nick@gemcutter.org'
      config.password = 'schwwwwing'
    end
    Gems.api_key

    # You can also find your API key at https://rubygems.org/profile/edit
    # We will attempt to load your API key from ~/.gem/credentails
    # You may also specify a custom API key
    Gems.configure do |config|
      config.key '701243f217cdf23b1370c7b66b65ca97'
    end

    # List all gems that you own
    puts Gems.gems

    # View all owners of a gem that you own
    puts Gems.owners 'gemcutter'

    # Add an owner to a RubyGem you own, giving that user permission to manage it
    puts Gems.add_owner 'josh@technicalpickles.com', 'gemcutter' [TODO]

    # Remove a user's permission to manage a RubyGem you own
    puts Gems.remove_owner 'josh@technicalpickles.com', 'gemcutter' [TODO]

    # List the webhooks registered under your account
    puts Gems.web_hooks

    # Add a webhook
    puts Gems.add_web_hook 'rails', 'http://example.com' [TODO]

    # Remove a webhook
    puts Gems.remove_web_hook 'rails', 'http://example.com' [TODO]

    # Test fire a webhook.
    puts Gems.fire_web_hook 'rails', 'http://example.com' [TODO]

    # Submit a gem to RubyGems.org
    puts Gems.push File.new 'gemcutter-0.2.1.gem' [TODO]

    # Remove a gem from RubyGems.org's index
    puts Gems.yank 'bills', '0.0.1', :platform => 'x86-darwin-10' [TODO]

    # Update a previously yanked gem back into RubyGems.org's index
    puts Gems.unyank 'bills', '0.0.1', :platform => 'x86-darwin-10' [TODO]

Contributing
------------
In the spirit of [free software](http://www.fsf.org/licensing/essays/free-sw.html), **everyone** is encouraged to help improve this project.

Here are some ways *you* can contribute:

* by using alpha, beta, and prerelease versions
* by reporting bugs
* by suggesting new features
* by writing or editing documentation
* by writing specifications
* by writing code (**no patch is too small**: fix typos, add comments, clean up inconsistent whitespace)
* by refactoring code
* by closing [issues](https://github.com/sferik/gems/issues)
* by reviewing patches

Submitting an Issue
-------------------
We use the [GitHub issue tracker](https://github.com/sferik/gems/issues) to track bugs and
features. Before submitting a bug report or feature request, check to make sure it hasn't already
been submitted. You can indicate support for an existing issuse by voting it up. When submitting a
bug report, please include a [Gist](https://gist.github.com/) that includes a stack trace and any
details that may be necessary to reproduce the bug, including your gem version, Ruby version, and
operating system. Ideally, a bug report should include a pull request with failing specs.

Submitting a Pull Request
-------------------------
1. Fork the project.
2. Create a topic branch.
3. Implement your feature or bug fix.
4. Add documentation for your feature or bug fix.
5. Run <tt>bundle exec rake doc:yard</tt>. If your changes are not 100% documented, go back to step 4.
6. Add specs for your feature or bug fix.
7. Run <tt>bundle exec rake spec</tt>. If your changes are not 100% covered, go back to step 6.
8. Commit and push your changes.
9. Submit a pull request. Please do not include changes to the gemspec, version, or history file. (If you want to create your own version for some reason, please do so in a separate commit.)

Copyright
---------
Copyright (c) 2011 Erik Michaels-Ober.
See [LICENSE](https://github.com/sferik/gems/blob/master/LICENSE.md) for details.
