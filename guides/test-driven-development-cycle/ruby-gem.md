# Implementing Task Cycle: Ruby Gem

This details specific steps and commands for the task cycle when working on a Ruby gem within this project.

* Scaffold with `bundle gem my_gem`—comes with Rake tasks.
* Follow the standard [Test -> Code -> Refactor cycle](docs-dev/guides/test-driven-development-cycle.md) using RSpec/RuboCop as in Ruby applications.
* After tests pass, `rake release` builds the gem and pushes to RubyGems (when not in a protected branch). citeturn0search3
* Docs generated with YARD; version bumped in `lib/my_gem/version.rb`.
