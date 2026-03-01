---
id: 8no000
title: "Retro: Test Performance Optimization"
type: standard
tags: []
created_at: "2025-12-25 00:00:00"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8no000-test-performance-optimization.md
---
# Retro: Test Performance Optimization

**Date**: 2025-12-25
**Context**: Optimized ace-test-runner integration tests from 28.90s to 3.69s (7.8x speedup) by applying proven stubbing patterns from ace-git
**Author**: AI Agent (Claude Code)
**Type**: Standard

## What Went Well

- **Significant performance gain**: 7.8x speedup (28.90s → 3.69s) on test suite
- **Pattern reuse**: Successfully applied stubbing patterns proven in ace-git (99.8% improvement there)
- **Balanced approach**: Kept 3 real integration tests for end-to-end validation while stubbing 27 tests
- **Shared infrastructure**: Created reusable TestRunnerMocks fixture in ace-support-test-helpers
- **All tests passing**: 124 tests, 331 assertions, 0 failures after optimization
- **Clean implementation**: Minimal changes, clear separation between stubbed and real tests

## What Could Be Improved

- Initial attempt used chained `define_singleton_method` which failed (Ruby returns symbol, not object)
- Had to debug `NameError: uninitialized constant` for TestRunnerMocks (missing require in test_helper.rb)
- Two tests needed custom output parameters to match expected package names in assertions

## Key Learnings

- **Open3.stub pattern**: Subprocess execution can be stubbed by wrapping the real call inside the stub block
- **Status mocking**: `Object.new` with `define_singleton_method` creates flexible mock objects (but can't chain calls)
- **Integration vs unit balance**: Keeping a small percentage (~10%) of real integration tests provides validation while maintaining speed
- **Shared fixtures payoff**: Centralized mock fixtures in ace-support-test-helpers are reusable across all gems
- **Test structure matters**: Flat test structure and clear helper methods make refactoring easier

## Technical Details

### Implementation Approach

**Problem**: `PackageArgumentTest` used `Open3.capture3` to spawn real subprocesses, each running full test suites

**Solution**: Created `run_ace_test_with_mock()` helper that:
1. Generates mock test output using TestRunnerMocks
2. Creates mock status object with `success?` and `exitstatus` methods
3. Stubs `Open3.capture3` to return mocked data
4. Calls real `run_ace_test()` inside stub block

**Key Files Modified**:
- `ace-support-test-helpers/lib/ace/test_support/fixtures/test_runner_mocks.rb` (new, 86 lines)
- `ace-support-test-helpers/lib/ace/test_support.rb` (added require)
- `ace-test-runner/test/test_helper.rb` (added require for ace/test_support)
- `ace-test-runner/test/integration/package_argument_test.rb` (refactored 27/30 tests)

**Tests Kept Real** (for end-to-end validation):
- `test_run_tests_for_package_by_name` - validates package name resolution
- `test_package_with_target` - validates package + target combination
- `test_package_prefixed_file_path` - validates package-prefixed file syntax

### Performance Breakdown

- Before: 28.90s (30 tests, all subprocess)
- After: 3.69s total
  - 27 stubbed tests: ~0.1s
  - 3 real tests: ~3.5s

### Mock Status Object Pattern

```ruby
# Correct approach (non-chained):
def self.mock_success_status
  status = Object.new
  status.define_singleton_method(:success?) { true }
  status.define_singleton_method(:exitstatus) { 0 }
  status
end

# Wrong approach (chaining fails - returns symbol):
Object.new.define_singleton_method(:success?) { true }
  .define_singleton_method(:exitstatus) { 0 }  # TypeError
```

## Action Items

### Stop Doing

- Spawning subprocesses in unit/integration tests when mocking can validate the same logic
- Chaining `define_singleton_method` calls (Ruby returns method name symbol, not object)

### Continue Doing

- Using Open3.stub pattern for subprocess testing
- Keeping small percentage of real integration tests for validation
- Creating shared fixtures in ace-support-test-helpers for reuse
- Documenting performance optimizations with before/after metrics

### Start Doing

- Profiling test suites before optimization to identify true bottlenecks
- Applying stubbing patterns to other slow test suites in the mono-repo
- Adding performance assertions to CI (fail if test suite exceeds threshold)

## Additional Context

**Commit**: 48dcc415 `feat(ace-test-runner): Optimize integration tests by stubbing Open3 subprocess calls`

**Related Work**:
- ace-git achieved 99.8% test speed improvement using similar stubbing patterns (commit 85e53bf7)
- Pattern documented in docs/testing-patterns.md: "Testing Classes with Multiple External Dependencies"

**Files Changed**: 5 files, 167 insertions, 20 deletions
