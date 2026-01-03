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

- [ ] Test suite runs in <5 seconds (currently 13.01s)
- [ ] All 380 tests pass
- [ ] No real git init via backticks (use stubs)
- [ ] Stub chains simplified

## Objective

Reduce ace-git-worktree test execution time by 62%+ (from 13s to <5s) by replacing real git commands with stubs and simplifying nested stub chains.

## Scope of Work

### Root Cause Analysis (from investigation)
- Real git init via backticks in contract tests (worktree_manager_contract_test.rb:21-24)
- system() calls in cli_test.rb:77-79
- 4-layer nested stub chains in with_git_stubs helper (test_helper.rb:63-72)
- Multiple Dir.mktmpdir calls (4 files)

### Key Files to Modify
- `ace-git-worktree/test/integration/worktree_manager_contract_test.rb:21-24` - backticks
- `ace-git-worktree/test/commands/cli_test.rb:77-79` - system() calls
- `ace-git-worktree/test_helper.rb:63-72` - with_git_stubs (4 layers)

### Optimizations
1. Replace backtick git commands with GitCommand stubs
2. Simplify nested stub chains with composite mocks
3. Share mock repo setup across test classes
4. Use with_temp_dir consistently

## Out of Scope

- ❌ Changes to production code in ace-git-worktree
- ❌ Reducing test coverage