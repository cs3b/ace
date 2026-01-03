---
id: v.0.9.0+task.174
status: in-progress
priority: medium
estimate: 2h
dependencies: []
worktree:
  branch: 174-optimize-ace-taskflow-test-performance-10s-to-under-5s
  path: "../ace-task.174"
  created_at: '2026-01-03 13:08:17'
  updated_at: '2026-01-03 13:08:17'
---

# Optimize ace-taskflow test performance (10s to under 5s)

## Behavioral Specification

### User Experience
- **Input**: Developer runs `ace-test ace-taskflow` to execute test suite
- **Process**: Tests execute with test_mode enabled and optimized filesystem setup
- **Output**: Full test results in <5 seconds (down from 9.77s)

### Expected Behavior
Developers experience faster test execution. Tests use with_real_config helper instead of disabling test_mode directly. Test factory filesystem creation is optimized.

### Success Criteria

- [ ] Test suite runs in <5 seconds (currently 9.77s)
- [ ] All 1175 tests pass
- [ ] Tests use with_real_config helper properly
- [ ] Filesystem creation optimized in test_factory.rb

## Objective

Reduce ace-taskflow test execution time by 49%+ (from 10s to <5s) by properly using test_mode and optimizing test factory filesystem creation.

## Scope of Work

### Root Cause Analysis (from investigation)
- Tests explicitly disable test_mode (task_manager_idempotent_test.rb:10)
- with_test_project creates 15+ files per test (test_factory.rb:93-147)
- Multiple Dir.glob chains in task/idea loaders
- 1175 tests with many using with_test_project

### Key Files to Modify
- `ace-taskflow/test/organisms/task_manager_idempotent_test.rb:10` - use with_real_config
- `ace-taskflow/test/molecules/config_loader_test.rb` - use with_real_config
- `ace-taskflow/test/support/test_factory.rb:93-147` - optimize filesystem creation

### Optimizations
1. Use `with_real_config` helper instead of `test_mode = false`
2. Create mock task/idea structures for unit tests (avoid filesystem)
3. Cache test factory filesystem creation where possible
4. Use mocked loaders in unit tests

## Out of Scope

- ❌ Changes to production code in ace-taskflow
- ❌ Reducing test coverage