---
id: v.0.9.0+task.171
status: in-progress
priority: medium
estimate: 3h
dependencies: []
worktree:
  branch: 171-optimize-ace-git-worktree-test-performance-13s-to-under-5s
  path: "../ace-task.171"
  created_at: '2026-01-03 13:06:41'
  updated_at: '2026-01-03 13:06:41'
---

# Optimize ace-git-worktree test performance (13s to under 5s)

## Behavioral Specification

### User Experience
- **Input**: Developer runs `ace-test ace-git-worktree` to execute test suite
- **Process**: Tests execute with GitCommand stubs instead of real git operations
- **Output**: Full test results in <5 seconds (down from 13.01s)

### Expected Behavior
Developers experience faster test execution. Backtick git commands replaced with stubs. Nested stub chains simplified with composite mocks.

### Success Criteria

- [ ] Test suite runs in <5 seconds (currently ~6.7s, originally 13.01s)
- [ ] All 380 tests pass
- [ ] No real git init via backticks (use stubs)
- [ ] Stub chains simplified

## Objective

Reduce ace-git-worktree test execution time from ~6.7s to <5s by eliminating real git commands and reducing external process calls.

## Current Performance Analysis

**Current state**: 6.7s (already improved from original 13s)
**Target**: <5s
**Gap**: ~1.7s to eliminate

### Performance Breakdown by Test Group

| Group | Time | Bottleneck |
|-------|------|------------|
| molecules | 2.7s | Real git init in worktree_remover_test.rb setup |
| commands | 2.0s | Real ace-taskflow calls in security/validation tests |
| integration | 1.3s | Real git init in contract_test.rb setup |
| organisms | 0.6s | OK |
| smoke | 0.08s | OK |
| atoms | 0.03s | OK |
| models | 0.01s | OK |

### Slowest Individual Tests

1. `test_fetch_with_nil_or_empty_input` - 0.48s (molecules)
2. `test_fetch_with_dangerous_inputs` - 0.48s (molecules)
3. `test_run_with_invalid_task_id` - 0.43s (commands)
4. `test_security_validation_on_paths_and_tasks` - 0.36s (commands)
5. `test_security_validation_in_task_ids` - 0.18s (commands)

## Scope of Work

### Root Cause Analysis (updated from investigation)

1. **Real git init in test setup** (~1.1s total):
   - `worktree_remover_test.rb:260-267` - `setup_git_repo` runs git init + config (11 tests × 68ms = 748ms)
   - `worktree_manager_contract_test.rb:21-24` - backtick git init (5 tests × 68ms = 340ms)

2. **Real ace-taskflow calls** (~1.0s total):
   - `test_run_with_invalid_task_id` (0.43s) - runs real ace-taskflow to validate
   - `test_security_validation_on_paths_and_tasks` (0.36s) - 7 iterations
   - `test_security_validation_in_task_ids` (0.18s) - 10 iterations

3. **Note: Already optimized**:
   - `cli_test.rb:77-79` system() calls are in a SKIPPED test
   - `test_helper.rb:63-72` with_git_stubs pattern is already in use

### Key Files to Modify

1. `ace-git-worktree/test/molecules/worktree_remover_test.rb`
   - Remove `setup_git_repo` call
   - Tests already use mocks, don't need real git repo

2. `ace-git-worktree/test/integration/worktree_manager_contract_test.rb`
   - Remove backtick git init from setup
   - Contract tests use mocks, real git not needed

3. `ace-git-worktree/test/commands/create_command_test.rb`
   - Stub ace-taskflow calls in `test_run_with_invalid_task_id`

4. `ace-git-worktree/test/commands/switch_command_test.rb`
   - Stub external calls in security validation tests

5. `ace-git-worktree/test/commands/cli_test.rb`
   - Stub ace-taskflow in security validation tests

## Implementation Plan

### Execution Steps

- [ ] **Step 1**: Remove `setup_git_repo` from worktree_remover_test.rb
  - Lines 9, 260-267: Remove setup_git_repo call and method
  - Tests use mocks; real git repo unnecessary
  > TEST: Verify tests still pass
  > Assert: 11 tests pass without real git init
  > Command: ace-test ace-git-worktree/test/molecules/worktree_remover_test.rb

- [ ] **Step 2**: Remove git init from worktree_manager_contract_test.rb
  - Lines 21-24: Remove backtick git commands from setup
  - Contract tests use mock fixtures, not real git
  > TEST: Verify contract tests pass
  > Assert: 5 tests pass without git init
  > Command: ace-test ace-git-worktree integration

- [ ] **Step 3**: Stub ace-taskflow in create_command_test.rb
  - `test_run_with_invalid_task_id`: Add Open3 stub for ace-taskflow
  - Pattern: Use existing `stub_ace_taskflow_output` helper
  > TEST: Verify test_run_with_invalid_task_id runs fast
  > Assert: Test completes in <50ms
  > Command: ace-test ace-git-worktree commands --profile 5

- [ ] **Step 4**: Stub external calls in switch_command_test.rb
  - `test_security_validation_on_paths_and_tasks`: Stub GitCommand and TaskFetcher
  - Validation happens before external calls, so may not need stubs
  > TEST: Verify security validation tests run fast
  > Assert: test_security_validation_on_paths_and_tasks <100ms
  > Command: ace-test ace-git-worktree commands --profile 10

- [ ] **Step 5**: Stub ace-taskflow in cli_test.rb security tests
  - `test_security_validation_in_task_ids`: Stub Open3.capture3
  > TEST: Verify CLI security tests run fast
  > Assert: test_security_validation_in_task_ids <50ms
  > Command: ace-test ace-git-worktree commands --profile 10

- [ ] **Step 6**: Run full test suite and verify performance
  > TEST: Full suite performance
  > Assert: All 380 tests pass in <5 seconds
  > Command: ace-test ace-git-worktree --profile 20

## Acceptance Criteria

- [ ] AC 1: Test suite runs in <5 seconds (currently ~6.7s)
- [ ] AC 2: All 380 tests pass with 0 failures
- [ ] AC 3: No real git init commands in test setup (grep verification)
- [ ] AC 4: Security validation tests use stubs, not real commands

## Out of Scope

- ❌ Changes to production code in ace-git-worktree
- ❌ Reducing test coverage
- ❌ Changes to already-skipped tests