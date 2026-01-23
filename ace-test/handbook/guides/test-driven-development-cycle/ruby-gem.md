---
name: tdd-ruby-gem
description: Task cycle for Ruby gem development
doc-type: guide
purpose: TDD workflow for Ruby gems
search_keywords:
  - ruby
  - gem
  - tdd
  - rake release
  - rubygems
update:
  frequency: on-change
  last-updated: '2026-01-23'
---

# Implementing Task Cycle: Ruby Gem

This details specific steps and commands for the task cycle when working on a Ruby gem within this project.

* Scaffold with `bundle gem my_gem`—comes with Rake tasks.
* Follow the standard [Test -> Code -> Refactor cycle](./testing-tdd-cycle.g.md) using
  RSpec/RuboCop as in Ruby applications.
* After tests pass, `rake release` builds the gem and pushes to RubyGems (when not in a protected
  branch).
* Docs generated with YARD; version bumped in `lib/my_gem/version.rb`.
