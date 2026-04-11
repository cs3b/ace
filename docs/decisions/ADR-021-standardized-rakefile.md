# ADR-021: Standardized Rakefile

## Status
Accepted
Date: October 14, 2025

## Context

With 15+ gems in the mono-repo, test execution needed standardization. Early gems had different Rakefile configurations:
- Some used RSpec, others Minitest
- Different task names (test vs spec)
- Inconsistent default tasks
- Missing CI compatibility aliases
- Varied test file patterns

This created confusion and made CI/CD setup complex.

## Decision

All ace-* gems **must** use standardized Rakefile with Rake::TestTask for minitest.

### Standard Rakefile Template

```ruby
# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

# CI compatibility: Allow 'rake spec' to run tests
task :spec => :test

# Default task
task default: :test
```

### Requirements

**DO:**
- ✅ Use `Rake::TestTask` for test execution
- ✅ Name main task `:test`
- ✅ Include `:spec => :test` alias for CI compatibility
- ✅ Set `default: :test` as default task
- ✅ Include both "test" and "lib" in load path
- ✅ Use `test/**/*_test.rb` pattern for files
- ✅ Include `bundler/gem_tasks` for gem management

**DON'T:**
- ❌ Use custom test runners
- ❌ Skip CI compatibility alias
- ❌ Use different task names per gem
- ❌ Hardcode test file paths
- ❌ Skip default task definition

### Task Names

```bash
# Standard commands that work in all gems
rake                  # Runs tests (default task)
rake test             # Runs tests explicitly
rake spec             # CI compatibility alias
rake build            # Build gem (from bundler/gem_tasks)
rake install          # Install gem locally (from bundler/gem_tasks)
rake release          # Release gem (from bundler/gem_tasks)
```

### Test File Discovery

Pattern `test/**/*_test.rb` finds all test files:
```
test/
├── gem_test.rb              # ✓ Found
├── atoms/parser_test.rb     # ✓ Found
├── molecules/loader_test.rb # ✓ Found
└── integration/cli_test.rb  # ✓ Found
```

### Load Path Configuration

```ruby
t.libs << "test"  # Enables: require 'test_helper'
t.libs << "lib"   # Enables: require 'ace/gem'
```

Without these, tests would need:
```ruby
require_relative '../lib/ace/gem'  # Verbose
```

With load path:
```ruby
require 'ace/gem'  # Clean
```

## Consequences

### Positive

- **Consistency**: Same Rakefile across all gems
- **CI Compatibility**: `rake spec` works everywhere
- **Simple Default**: `rake` runs tests automatically
- **Gem Tasks**: Bundler tasks included automatically
- **Discoverability**: Standard tasks work as expected
- **Maintenance**: Easy to update all gems if needed

### Negative

- **Minitest Only**: Pattern assumes minitest (no RSpec)
- **Limited Flexibility**: Some gems might want custom tasks
- **Migration**: Existing custom Rakefiles need updating

### Neutral

- **Task Overhead**: Bundler tasks added even if not used
- **Convention Over Configuration**: Trades flexibility for consistency

## Examples from Production

### ace-lint (Standard)
```ruby
# Rakefile
require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test" << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :spec => :test
task default: :test
```

### ace-docs (With Additional Tasks)
```ruby
# Rakefile
require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test" << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :spec => :test
task default: :test

# Custom task (optional)
desc "Check documentation status"
task :check_docs do
  require_relative 'lib/ace/docs'
  # Custom logic...
end
```

### ace-task (Extended)
```ruby
# Rakefile
require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test" << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :spec => :test
task default: :test

# Additional custom tasks
namespace :test do
  desc "Run only fast tests"
  task :fast do
    # Custom test subset...
  end
end
```

## Integration with CI/CD

### GitHub Actions
```yaml
# .github/workflows/ci.yml
jobs:
  test:
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true
      - run: rake test  # or 'rake' or 'rake spec' - all work
```

### CircleCI
```yaml
# .circleci/config.yml
jobs:
  test:
    steps:
      - checkout
      - ruby/install-deps
      - run: rake spec  # CI compatibility alias
```

## Testing the Rakefile

```bash
# Verify Rakefile works
cd ace-gem
rake --tasks              # List available tasks
rake test                 # Run tests
rake                      # Run default (test)
rake spec                 # CI alias
```

Expected output:
```
rake build      # Build ace-gem-x.y.z.gem
rake install    # Build and install ace-gem-x.y.z.gem
rake release    # Create tag and release gem
rake spec       # Run tests
rake test       # Run tests
```

## Customization Guidelines

**Standard tasks** (must include):
- `rake test` - Main test task
- `rake spec => :test` - CI compatibility
- `task default: :test` - Default behavior

**Custom tasks** (allowed):
- Add namespace (e.g., `namespace :lint`)
- Add supplementary tasks (e.g., `:check_docs`)
- Don't override standard tasks
- Don't change default task

**Example custom task:**
```ruby
desc "Run linter"
task :lint do
  sh "rubocop"
end

# Add to default if desired
task default: [:test, :lint]
```

## Test Options

### Verbose Output
```ruby
Rake::TestTask.new(:test) do |t|
  t.libs << "test" << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true  # Show test names
end
```

### Warning Flags
```ruby
Rake::TestTask.new(:test) do |t|
  t.libs << "test" << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = true  # Enable Ruby warnings
end
```

## Related Decisions

- **ADR-017**: Flat Test Structure - test file organization
- **ADR-015**: Mono-Repo Migration - context for standardization
- **ace-test-runner**: Unified test execution across gems
- **ace-test-support**: Shared testing infrastructure

## References

- **Rake Documentation**: https://ruby.github.io/rake/
- **Rake::TestTask**: https://ruby.github.io/rake/Rake/TestTask.html
- **Bundler Gem Tasks**: https://bundler.io/guides/creating_gem.html
- **Minitest**: https://github.com/minitest/minitest

---

This ADR establishes standardized Rakefile with Rake::TestTask as mandatory for all ACE gems, ensuring consistent test execution, CI compatibility, and maintainability.
