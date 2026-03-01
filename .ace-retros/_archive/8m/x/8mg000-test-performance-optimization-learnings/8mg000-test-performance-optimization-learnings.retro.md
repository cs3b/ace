---
id: 8mg000
title: "Retro: Test Performance Optimization - Eliminating Sleep Delays"
type: self-review
tags: []
created_at: "2025-11-17 00:00:00"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8mg000-test-performance-optimization-learnings.md
---
# Retro: Test Performance Optimization - Eliminating Sleep Delays

**Date**: 2025-11-17
**Context**: Comprehensive test suite optimization for ace-review, eliminating sleep delays in retry tests
**Author**: Development Team
**Type**: Self-Review

## What Went Well

- **Systematic profiling approach**: Used `ace-test --profile` to identify exact bottlenecks (4 tests taking 1 second each)
- **Incremental optimization**: Fixed atoms layer first (4s improvement), then molecules layer (1s improvement)
- **Coverage preservation**: All 254 tests continue to pass with full coverage maintained
- **Clear documentation**: Each commit documented performance improvements with before/after metrics
- **Collaborative debugging**: User-guided approach to finding profiling tools (`--profile` flag suggestion)

## What Could Be Improved

- **Initial test design**: Retry tests should have stubbed sleep from the start
- **Earlier profiling**: Could have profiled tests during initial implementation
- **Pattern consistency**: Some tests already stubbed sleep correctly, but pattern wasn't consistently applied

## Key Learnings

### Testing Retry Logic Without Actual Delays

**Core Principle**: When testing retry logic with exponential backoff, stub the `sleep` method to verify behavior without actual time delays.

**Pattern Discovery**:
```ruby
# ❌ BAD: Actual sleep delays (1 second per retry)
def test_retry_succeeds_after_retries
  result = RetryWithBackoff.execute do
    attempt < 2 ? error_result : success_result
  end
  assert result[:success]
end

# ✅ GOOD: Stub sleep to eliminate delays
def test_retry_succeeds_after_retries
  RetryWithBackoff.stub :sleep, ->(_time) {} do
    result = RetryWithBackoff.execute do
      attempt < 2 ? error_result : success_result
    end
    assert result[:success]
  end
end
```

**Why this works**:
- The retry logic is fully tested (attempts, backoff calculation, error handling)
- No actual time is wasted sleeping
- Tests run 40-100x faster
- Coverage remains identical

### Performance Impact Analysis

**Optimization Journey**:

| Stage | Atoms | Molecules | Total | Improvement |
|-------|-------|-----------|-------|-------------|
| Original | 4.14s | 3.23s | 8.14s | baseline |
| After atoms fix | 0.10s | 3.23s | 4.16s | 49% faster |
| After molecules fix | 0.10s | 2.23s | 3.16s | 61% faster |

**Total Impact**: 5 seconds saved (2.5× faster suite)

### Test Profiling Methodology

**Tools Used**:
```bash
# Profile slowest tests
ace-test --profile 10

# Output shows:
# 1. test_execute_uses_custom_retryable_check             1.000s
# 2. test_execute_raises_error_after_max_retries          1.000s
# ...
```

**Analysis Pattern**:
1. Run profiling to identify slow tests
2. Read test implementation to understand why
3. Identify actual sleep calls vs. stubbed ones
4. Apply stubbing pattern consistently
5. Verify performance improvement

### Module Reference Requirements

**Issue encountered**:
```ruby
# ❌ Failed in molecules layer test
RetryWithBackoff.stub :sleep, ->(_time) {}
# Error: uninitialized constant GhPrFetcherTest::RetryWithBackoff
```

**Solution**:
```ruby
# ✅ Use full module path
Ace::Review::Atoms::RetryWithBackoff.stub :sleep, ->(_time) {}
```

**Why**: When testing molecules that use atoms, fully qualify atom references to avoid namespace issues.

## Action Items

### Stop Doing

- Writing retry tests without stubbing sleep
- Assuming test performance is "good enough" without profiling
- Leaving inconsistent patterns across similar tests

### Continue Doing

- Using `ace-test --profile` to identify performance bottlenecks
- Documenting performance improvements with metrics in commit messages
- Maintaining full test coverage during optimizations
- Incrementally optimizing (one layer at a time)

### Start Doing

- **Stub sleep by default in retry tests**: Make this the standard pattern
- **Profile tests during initial development**: Catch performance issues early
- **Create test performance guidelines**: Document this pattern for future tests
- **Review similar patterns**: Look for other sleep/delay situations in tests

## Technical Details

### Files Modified

1. **test/atoms/retry_with_backoff_test.rb** (commit 56689b48)
   - Added sleep stubs to 4 tests
   - Reduced atoms layer from 4.14s to 0.10s (97% faster)

2. **test/molecules/gh_pr_fetcher_test.rb** (commit aa259ff9)
   - Added sleep stub to 1 test
   - Reduced molecules layer from 3.23s to 2.23s (31% faster)

### Stubbing Pattern

**Standard approach for retry tests**:
```ruby
def test_retry_behavior
  # Stub sleep at the module level
  ModuleName::RetryWithBackoff.stub :sleep, ->(_time) {} do
    # Test retry logic here
    result = ModuleName.method_that_retries
    # Assertions
  end
end
```

**Key points**:
- Use full module path when testing cross-layer interactions
- Lambda accepts time parameter but ignores it: `->(_time) {}`
- Wrap entire test logic inside stub block
- Sleep stubbing doesn't affect retry count or backoff calculation verification

### Earlier Optimization (commit 87a7242b)

**First approach**: Reduced retry counts in tests
- Reduced max_retries from 3-5 to 2-3
- Saved ~4 seconds but still had actual sleep delays
- Later superseded by sleep stubbing approach

**Lesson**: Reducing retry counts helps but stubbing eliminates the problem entirely

## Pattern Identification

### Reusable Test Helper Pattern

**Potential future enhancement**:
```ruby
# test/test_helper.rb
module TestHelpers
  # Stub sleep for retry tests
  def without_sleep(&block)
    Ace::Review::Atoms::RetryWithBackoff.stub :sleep, ->(_time) {}, &block
  end
end

# Usage in tests:
def test_retry_behavior
  without_sleep do
    result = @fetcher.fetch_with_retry
    assert result[:success]
  end
end
```

**Benefits**:
- Cleaner test code
- Consistent pattern across all retry tests
- Easier to maintain

### Code Quality Insight

**Discovery**: Some tests already had sleep stubbing:
- `test_execute_uses_exponential_backoff` (line 74)
- `test_execute_caps_backoff_at_max_backoff` (line 90)
- `test_execute_with_custom_backoff_values` (line 200)

**Pattern**: Tests that verify backoff timing had stubs, but tests that verify retry behavior didn't. This inconsistency led to performance issues.

**Future guideline**: **ALL retry tests should stub sleep**, regardless of what aspect they're testing.

## Cookbook Opportunities

### Test Performance Optimization Cookbook Entry

**Proposed Topic**: "Optimizing Retry Tests: Eliminating Sleep Delays"

**Content Structure**:
1. **Problem**: Tests with retry logic run slowly due to actual sleep calls
2. **Solution**: Stub sleep method to verify behavior without delays
3. **Implementation**: Step-by-step pattern with examples
4. **Profiling**: How to identify slow tests
5. **Verification**: Ensuring coverage remains intact

**Target Audience**: Developers writing tests for retry/backoff logic in any Ruby project

### Tool Proposals

**ace-test enhancement idea**:
```bash
# Automatically detect and warn about sleep calls in tests
ace-test --detect-delays

# Output:
# ⚠️  test/atoms/retry_test.rb:42 - Contains actual sleep(1) call
# ⚠️  test/molecules/fetcher_test.rb:116 - Contains actual sleep(2) call
#
# Suggestion: Consider stubbing sleep in retry tests
```

## Additional Context

**Related Commits**:
- 56689b48: perf(tests): Stub sleep in 4 retry tests to eliminate 4s delay
- aa259ff9: perf(tests): Stub sleep in GhPrFetcher retry test
- 87a7242b: test(retry_with_backoff): Reduce retry counts for performance

**Performance Metrics**:
- Initial suite: 8.14s for 254 tests
- Final suite: 3.16s for 254 tests
- Time saved per test run: 5 seconds
- Speedup factor: 2.5×

**Links**:
- Test performance analysis conversation: 2025-11-17 session
- ace-review gem: v0.17.0 (with GitHub PR review mode)
