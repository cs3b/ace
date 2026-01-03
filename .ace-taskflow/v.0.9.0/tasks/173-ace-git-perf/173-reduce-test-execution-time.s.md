---
id: v.0.9.0+task.173
status: draft
priority: medium
estimate: 2h
dependencies: []
---

# Optimize ace-git test performance (11s to under 5s)

## Behavioral Specification

### User Experience
- **Input**: Developer runs `ace-test ace-git` to execute test suite
- **Process**: Tests execute with consolidated Open3 mocking and optimized timeout tests
- **Output**: Full test results in <5 seconds (down from 11.02s)

### Expected Behavior
Developers experience faster test execution. Open3 mock setup is consolidated. Timeout tests use mock delays instead of real sleep.

### Success Criteria

- [ ] Test suite runs in <5 seconds (currently 11.02s)
- [ ] All 446 tests pass
- [ ] Open3 mocking consolidated
- [ ] No real sleep(10) in tests

## Objective

Reduce ace-git test execution time by 55%+ (from 11s to <5s) by consolidating Open3 mock setup and optimizing timeout tests.

## Scope of Work

### Root Cause Analysis (from investigation)
- Large test files (repo_status_loader_test.rb: 534 lines)
- sleep(10) in timeout test (pr_metadata_fetcher_test.rb:142)
- Config reset overhead in test_helper.rb:10-14
- Heavy Open3 mocking for gh CLI calls

### Key Files to Modify
- `ace-git/test/molecules/pr_metadata_fetcher_test.rb:142` - sleep(10) → mock timeout
- `ace-git/test/organisms/repo_status_loader_test.rb` - 534 lines, potential split
- `ace-git/test_helper.rb:10-14` - config reset optimization

### Optimizations
1. Replace sleep(10) with mock timeout behavior
2. Consolidate Open3 mock setup to reduce stub overhead
3. Consider splitting large test files if beneficial
4. Optimize config reset pattern

## Out of Scope

- ❌ Changes to production code in ace-git
- ❌ Reducing test coverage
