---
id: v.0.2.0+task.5
status: pending
priority: high
estimate: 4h
dependencies: []
---

# Fix Ruby 3.4 CI Bundler Setup Issue Causing dry-cli Loading Failures

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 3 lib/ exe/ spec/integration/ | head -20
```

_Result excerpt:_

```
lib/
├── coding_agent_tools/
│   ├── cli.rb
│   ├── commands/
│   └── ...
exe/
├── llm-gemini-query
spec/integration/
├── llm_gemini_query_integration_spec.rb
```

## Objective

Fix the Ruby 3.4 CI environment issue where the `dry-cli` gem cannot be loaded, causing all 22 integration tests for the `llm-gemini-query` command to fail with `LoadError: cannot load such file -- dry/cli`. Since tests work locally but fail in CI, this indicates a bundler setup issue in the GitHub Actions environment that needs to be addressed.

## Scope of Work

- Investigate and resolve the `dry-cli` gem loading failure in Ruby 3.4 CI environment
- Add explicit bundler setup steps to CI workflow if needed
- Ensure proper bundler configuration in GitHub Actions
- Validate that all integration tests pass in Ruby 3.4 CI environment

### Deliverables

#### Modify

- `.github/workflows/ci.yml` - Add explicit bundler setup step before running tests
- Potentially `Gemfile` or `coding_agent_tools.gemspec` if dependency constraints need adjustment
- CI configuration to ensure proper gem loading in Ruby 3.4 environment

#### Verify

- All 22 integration tests pass in Ruby 3.4
- CLI commands execute successfully in Ruby 3.4
- No regression in other Ruby versions (3.1, 3.2, 3.3)

## Phases

1. **Investigate** - Analyze the CI vs local environment differences for Ruby 3.4
2. **Diagnose** - Identify bundler setup gaps in GitHub Actions workflow
3. **Implement** - Add explicit bundler/setup or require 'bundler/setup' step to CI
4. **Validate** - Ensure all tests pass in CI environment

## Implementation Plan

### Planning Steps

* [ ] Compare local vs CI environment setup for Ruby 3.4
  > TEST: Environment Analysis Complete
  > Type: Pre-condition Check
  > Assert: Differences between local and CI bundler setup are identified
  > Command: bin/test --check-analysis-exists ci-bundler-analysis.md
* [ ] Research GitHub Actions ruby/setup-ruby bundler configuration best practices
* [ ] Identify missing bundler setup steps in CI workflow
* [ ] Review if explicit `require 'bundler/setup'` is needed before gem loading

### Execution Steps

- [ ] Add explicit bundler setup step to `.github/workflows/ci.yml` before running tests
  > TEST: CI Configuration Updated
  > Type: Action Validation
  > Assert: CI workflow includes proper bundler setup for Ruby 3.4
  > Command: grep -A5 -B5 "bundle" .github/workflows/ci.yml
- [ ] Test the updated CI configuration by triggering a Ruby 3.4 build
- [ ] Add `bundle exec` prefix to test commands if not already present
  > TEST: Bundle Exec Usage
  > Type: Action Validation
  > Assert: Test commands use bundle exec for proper gem loading
  > Command: grep "bin/test" .github/workflows/ci.yml
- [ ] Verify CLI command execution works in CI environment
  > TEST: CLI Startup Check in CI
  > Type: Action Validation
  > Assert: CLI command starts without LoadError in CI
  > Command: bundle exec exe/llm-gemini-query --help
- [ ] Run full integration test suite to verify all 22 tests pass in CI
  > TEST: Integration Tests Pass in CI
  > Type: Action Validation
  > Assert: All llm-gemini-query integration tests pass in Ruby 3.4 CI environment
  > Command: bundle exec rspec spec/integration/llm_gemini_query_integration_spec.rb
- [ ] Verify no regression in Ruby 3.2 and 3.3 CI builds

## Acceptance Criteria

- [ ] No `LoadError: cannot load such file -- dry/cli` errors in Ruby 3.4
- [ ] All 22 integration tests pass in Ruby 3.4 (currently failing)
- [ ] CLI commands execute successfully: `exe/llm-gemini-query --help` works
- [ ] No regression in Ruby 3.1, 3.2, 3.3 test suites
- [ ] CI pipeline passes for Ruby 3.4 build

## Out of Scope

- ❌ Adding new CLI features or commands
- ❌ Refactoring CLI architecture beyond fixing the CI setup issue
- ❌ Performance optimizations for CLI startup time
- ❌ Updating other gem dependencies unrelated to the bundler setup issue
- ❌ Fixing local development environment (since it already works locally)

## References

- CI logs showing specific failure: `docs-project/current/v.0.2.0-synapse/docs/2_Ruby 3.4.txt`
- Failed tests: 22 integration tests in `spec/integration/llm_gemini_query_integration_spec.rb`
- Error pattern: `<internal:/usr/lib/ruby/vendor_ruby/rubygems/core_ext/kernel_require.rb>:86:in 'require': cannot load such file -- dry/cli (LoadError)`
- Affected file: `lib/coding_agent_tools/cli.rb:3`
- Current CI workflow: `.github/workflows/ci.yml`
- Key insight: Tests work locally but fail in CI, indicating bundler setup issue in GitHub Actions environment
```

Now I'll prepare the commit command as requested:

```bash
bin/gc -i "Create task 5: Fix Ruby 3.4 dry-cli dependency loading issue causing 22 integration test failures"