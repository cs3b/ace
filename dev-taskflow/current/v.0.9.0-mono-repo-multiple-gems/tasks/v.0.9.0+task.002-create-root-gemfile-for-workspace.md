---
id: v.0.9.0+task.002
status: pending
priority: high
estimate: 2h
dependencies: [v.0.9.0+task.001]
---

# Create Root Gemfile for Workspace

## Objective

Set up the root Gemfile that manages all workspace gems and provides shared development/test dependencies. This enables consistent testing infrastructure across all gems and simplifies dependency management.

## Scope of Work

- Create root Gemfile with path-based gem references
- Configure shared development and test dependencies
- Set up bundler for workspace development
- Ensure Gemfile can be updated as new gems are added

### Deliverables

#### Create

- Gemfile (in repository root)
- Gemfile.lock (after bundle install)
- .bundle/config (optional, for local settings)

## Implementation Plan

### Planning Steps

* [ ] Determine shared test/development dependencies
* [ ] Review bundler workspace patterns
* [ ] Plan for incremental gem addition

### Execution Steps

- [ ] Create initial Gemfile with ace-core
  ```ruby
  source "https://rubygems.org"

  # Local workspace gems - flat in root (ace-* prefix)
  gem "ace-core", path: "ace-core"

  # Shared dev/test tools for all gems
  group :development, :test do
    gem "minitest", "~> 5.20"
    gem "minitest-reporters", "~> 1.6"
    gem "rake", "~> 13.0"
    gem "bundler", "~> 2.4"
  end
  ```

- [ ] Run bundle install to verify setup
  > TEST: Bundle install succeeds
  > Type: Manual verification
  > Assert: No dependency conflicts, Gemfile.lock created
  > Command: bundle install

- [ ] Test that ace-core is accessible
  > TEST: Workspace gem loading
  > Type: Manual verification
  > Assert: Can require ace-core from root
  > Command: bundle exec ruby -e "require 'ace/core'; puts Ace::Core::VERSION"

- [ ] Document update process for adding new gems
  ```ruby
  # To add new gem:
  # 1. Add to Gemfile: gem "ace-context", path: "ace-context"
  # 2. Run: bundle install
  # 3. Commit both Gemfile and Gemfile.lock
  ```

- [ ] Create bundle config for consistent settings
  ```bash
  bundle config set --local path 'vendor/bundle'
  bundle config set --local with 'development test'
  ```

## Acceptance Criteria

- [ ] Gemfile exists in repository root
- [ ] ace-core is referenced with path directive
- [ ] Shared test/dev dependencies are in groups
- [ ] Bundle install completes successfully
- [ ] Gemfile structure supports adding more gems
- [ ] Documentation for gem addition process

## Out of Scope

- ❌ Publishing gems to RubyGems
- ❌ Complex versioning strategies
- ❌ CI/CD bundle caching setup
- ❌ Production deployment configuration