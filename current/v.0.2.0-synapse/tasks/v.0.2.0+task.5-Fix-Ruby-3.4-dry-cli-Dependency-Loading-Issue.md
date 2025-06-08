---
id: v.0.2.0+task.5
status: in-progress
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

- `spec/integration/llm_gemini_query_integration_spec.rb` - Improve error messages to show command output on failure
- ✅ `.github/workflows/ci.yml` - Added explicit `bin/setup` step before running tests
- Potentially `Gemfile` or `coding_agent_tools.gemspec` if dependency constraints need adjustment (if needed after testing)

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
* [x] Research GitHub Actions ruby/setup-ruby bundler configuration best practices
* [x] Identify missing bundler setup steps in CI workflow - added `bin/setup` step
* [ ] Review if additional bundler configuration is needed after testing CI

### Execution Steps

- [x] **Improve integration test error reporting** - Modify integration tests to display actual command output when process status fails
  - [x] Create helper method to check process status with meaningful error messages
  - [x] Replace `expect(status).to be_success` with custom matcher that shows stdout/stderr on failure
  - [x] Update all integration tests to use the improved error reporting
  > TEST: Error Reporting Improved
  > Type: Action Validation
  > Assert: Integration tests show stderr/stdout output on failure instead of just boolean status
  > Command: grep -A10 -B5 "expect.*process.*success" spec/integration/llm_gemini_query_integration_spec.rb
- [x] Add explicit bundler setup step to `.github/workflows/ci.yml` before running tests
- [x] Add `require "bundler/setup"` to exe/llm-gemini-query to fix gem loading in CI
- [x] Fix 8 integration tests missing VCR subprocess environment setup
  > TEST: CI Configuration Updated
  > Type: Action Validation
  > Assert: CI workflow includes proper bundler setup for Ruby 3.4
  > Command: grep -A5 -B5 "Setup the dependencies" .github/workflows/ci.yml
- [ ] Test the updated CI configuration by triggering a Ruby 3.4 build
- [ ] Monitor CI results to see if `bin/setup` resolves the dry-cli loading issue
- [ ] Verify CLI command execution works in CI environment
  > TEST: CLI Startup Check in CI
  > Type: Action Validation
  > Assert: CLI command starts without LoadError in CI
  > Command: exe/llm-gemini-query --help
- [ ] Run full integration test suite to verify all 22 tests pass in CI
  > TEST: Integration Tests Pass in CI
  > Type: Action Validation
  > Assert: All llm-gemini-query integration tests pass in Ruby 3.4 CI environment
  > Command: bin/test # which runs rspec with proper setup
- [ ] Verify no regression in Ruby 3.2 and 3.3 CI builds

## Acceptance Criteria

- [x] Integration tests show meaningful error messages (stderr/stdout) when commands fail instead of just boolean status
  - [x] Failed tests display actual command output like: "Command failed with status 1. STDERR: <actual error>"
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
- Current CI workflow: `.github/workflows/ci.yml` (updated with `bin/setup` step)
- Key insight: Tests work locally but fail in CI, indicating bundler setup issue in GitHub Actions environment
- Status: CI configuration updated, bundler/setup added to executable, VCR setup fixed for 8 failing tests
- Error reporting improvement: Current tests show `expected '#<Process::Status: pid 1895 exit 1>.success?' to be truthy, got false` instead of actual command errors
```

Now I'll prepare the commit command as requested:

```bash
bin/gc -i "Create task 5: Fix Ruby 3.4 dry-cli dependency loading issue causing 22 integration test failures"