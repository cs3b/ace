---
id: v.0.9.0+task.170
status: in-progress
priority: medium
estimate: 3h
dependencies: []
worktree:
  branch: 170-optimize-ace-review-test-performance-14s-to-under-5s
  path: "../ace-task.170"
  created_at: '2026-01-03 13:06:17'
  updated_at: '2026-01-03 13:06:17'
---

# Optimize ace-review test performance (14s to under 5s)

## Behavioral Specification

### User Experience
- **Input**: Developer runs `ace-test ace-review` to execute test suite
- **Process**: Tests execute with shared mock git repo and consolidated context mocking
- **Output**: Full test results in <5 seconds (down from 13.97s)

### Expected Behavior
Developers experience faster test execution. Git initialization is replaced with stubs. Context mocking is consolidated to reduce setup overhead.

### Success Criteria

- [ ] Test suite runs in <5 seconds (currently 13.97s)
- [ ] All 478 tests pass
- [ ] No real git init in tests (use stubs)
- [ ] Context mocking consolidated

## Objective

Reduce ace-review test execution time by 64%+ (from 14s to <5s) by creating shared mock git repo fixtures and consolidating context mocking setup.

## Scope of Work

### Root Cause Analysis (from investigation)
- 9 files with Dir.mktmpdir calls
- Real git init in integration tests (multi_model_cli_test.rb:14-21)
- Multiple stub layers for ace-context mocking
- Sleep mocking in gh_pr_fetcher_test.rb

### Key Files to Modify
- `ace-review/test_helper.rb:22` - mktmpdir in every test setup
- `ace-review/test/integration/multi_model_cli_test.rb:14-21` - git init
- `ace-review/test/molecules/gh_pr_fetcher_test.rb` - sleep mocking

### Optimizations
1. Create shared mock git repo fixture (reuse across tests)
2. Replace real git init with GitCommand stubs
3. Consolidate context mocking setup to reduce duplication
4. Optimize sleep mocking patterns

## Out of Scope

- ❌ Changes to production code in ace-review
- ❌ Reducing test coverage