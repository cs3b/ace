---
id: 8ouo8f
title: "Performant Unit Tests - Cache Management & Random Slowness"
type: standard
tags: []
created_at: "2026-01-31 16:09:21"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8ouo8f-performant-unit-tests-cache-management.md
---
# Reflection: Performant Unit Tests - Cache Management & Random Slowness

**Date**: 2026-01-31
**Context**: Debugging and fixing random slow tests in ace-lint test suite
**Author**: Claude (Task 251)
**Type**: Technical Analysis

## What Went Well

- Systematic profiling with `ace-test --profile 5` revealed the pattern of random slowness
- Multiple test runs helped identify the non-deterministic nature of the problem
- Root cause analysis traced through multiple cache layers (ValidatorRegistry, BaseRunner)
- Final solution achieved consistent ~60-70ms test runs (down from 60ms-1.6s variance)

## What Could Be Improved

- Initial plan focused on config initialization (wrong root cause) - should have profiled subprocess calls earlier
- Iterative approach took many rounds - better understanding of cache architecture would have helped
- Some tests were modified multiple times before finding the right fix

## Key Learnings

### 1. Random Test Slowness = Cache Invalidation Problem

When tests are randomly slow (different tests each run), the issue is almost always:
- **Shared mutable state** being reset by some tests but not others
- **Test order sensitivity** due to Minitest shuffling
- **Cache invalidation** clearing expensive-to-recompute values

**Diagnostic approach**: Run tests multiple times with profiling. If different tests are slow each run, it's a cache/ordering issue, not a slow test.

### 2. Multiple Cache Layers Multiply Complexity

The ace-lint system had **two separate availability caches**:
1. `ValidatorRegistry.@availability_cache` - keyed by validator symbol (`:standardrb`)
2. `BaseRunner.@availability_cache` - keyed by command name (`"standardrb"`)

When code calls `ValidatorRegistry.available?(:standardrb)`, it:
1. Checks its own cache
2. Calls `StandardrbRunner.available?` which checks BaseRunner's cache
3. Caches result in both places

**Lesson**: Understand ALL cache layers before attempting fixes. A fix at one layer may not help if another layer is still cold.

### 3. Subprocess Calls Are Expensive

Real availability checks (`system("standardrb --version > /dev/null 2>&1")`) take ~0.5-1s each. In a test suite with 263 tests, even a few subprocess calls can dominate runtime.

**Pattern**: Tests should NEVER make real subprocess calls unless specifically testing subprocess behavior.

### 4. Stub Helpers Must Be Complete

When stubbing external calls in tests, ensure **all entry points** are covered:

```ruby
# INCOMPLETE - stubs :run but not :available?
StandardrbRunner.stub(:run, mock_result) do
  RubyLinter.lint(file)  # Calls available?() first, triggers subprocess!
end

# COMPLETE - stubs both
StandardrbRunner.stub(:available?, true) do
  StandardrbRunner.stub(:run, mock_result) do
    RubyLinter.lint(file)  # Fast - no subprocess
  end
end
```

### 5. Cache Resets Should Be Localized

**Anti-pattern**: Resetting caches in test setup affects ALL subsequent tests

```ruby
def setup
  StandardrbRunner.reset_availability_cache!  # Bad: affects other test files
end
```

**Better pattern**: Reset caches inside the stub helper, then pre-populate

```ruby
def stub_runner(available:)
  StandardrbRunner.reset_availability_cache!  # Reset
  StandardrbRunner.stub(:system_has_command?, available) do
    StandardrbRunner.available?  # Pre-populate cache with stub value
    yield
  end
  # After stub ends, cache has value for subsequent tests
end
```

### 6. Pre-warming Must Cover All Variants

When pre-warming caches at test suite startup:
- Identify ALL cache keys that will be needed
- Pre-warm ALL of them, not just the ones you think are important

```ruby
# test_helper.rb - pre-warm ALL availability caches
Ace::Lint::Atoms::ValidatorRegistry.available?(:standardrb)
Ace::Lint::Atoms::ValidatorRegistry.available?(:rubocop)
Ace::Lint::Atoms::StandardrbRunner.available?
Ace::Lint::Atoms::RuboCopRunner.available?
```

### 7. Test Interleaving Breaks Single-File Assumptions

Minitest shuffles tests by default. Tests from `standardrb_runner_test.rb` may run between tests from `ruby_linter_test.rb`.

**Assumption that fails**: "My setup runs before all my tests"
**Reality**: Your setup runs before each of your tests, but other tests run in between

**Solution**: Each test must be self-sufficient or helpers must leave caches in a valid state.

## Action Items

### Stop Doing

- Resetting shared caches in test setup methods
- Assuming tests run in file order
- Stubbing `:run` without also stubbing `:available?`

### Continue Doing

- Pre-warming expensive caches at test suite startup
- Running tests multiple times to detect ordering issues
- Profiling test suites to identify slow tests

### Start Doing

- Documenting cache architectures in test helpers
- Making stub helpers pre-populate caches before yielding
- Stubbing ALL entry points to expensive operations
- Adding cache pre-warm to any test that resets caches

## Technical Details

### Cache Architecture (ace-lint)

```
ValidatorRegistry.available?(:standardrb)
    └── @availability_cache[:standardrb] (miss)
        └── StandardrbRunner.available?
            └── BaseRunner.@availability_cache["standardrb"] (miss)
                └── system_has_command?("standardrb")
                    └── system("standardrb --version > /dev/null 2>&1")  # ~0.5-1s
```

### Fix Summary

1. **test_helper.rb**: Pre-warm all caches at require time
2. **Runner test helpers**: Reset + stub + pre-populate both runner caches
3. **ruby_linter_test.rb**: Add `available?` stubs to tests that only stubbed `:run`
4. **validator_chain_test.rb**: Move resets into helper, add pre-population

### Performance Results

| Metric | Before | After |
|--------|--------|-------|
| Best case | 60ms | 60ms |
| Worst case | 1.6s | 70ms |
| Variance | ~25x | ~1.2x |
| Consistency | Random | Consistent |

## Additional Context

- Related to Task 251: Optimize slow test suites
- Previous retro: `8oun6n-performant-unit-integration-tests.md`
- Builds on earlier work stubbing individual tests (v0.15.2)
- This fix addresses test-to-test cache pollution (v0.15.3)
