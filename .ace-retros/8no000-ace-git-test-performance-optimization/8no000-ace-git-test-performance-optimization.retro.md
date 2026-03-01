---
id: 8no000
title: "Retro: ace-git Test Performance Optimization"
type: conversation-analysis
tags: []
created_at: "2025-12-25 00:00:00"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8no000-ace-git-test-performance-optimization.md
---
# Retro: ace-git Test Performance Optimization

**Date**: 2025-12-25
**Context**: Optimizing ace-git unit tests from ~18s to ~7.3s through stubbing external calls
**Author**: Development Session
**Type**: Conversation Analysis

## What Went Well

- **Atoms tests achieved 99.8% improvement** (11.2s → 22ms) by stubbing real git calls
- **Clear root cause analysis** using test profiling (--profile 10) identified real git commands as bottleneck
- **User provided clear architectural direction**: "unit tests should not call external services"
- **Systematic approach** - atoms → molecules → organisms → models → commands → integration
- **Created follow-up task** (Task 156) for cross-package dependency issue rather than blocking

## What Could Be Improved

- **Organism tests still slow** (~5.7s) due to ace-core ConfigResolver cross-package dependency
- **Multiple stubbing attempts failed** before finding working approach (stub timing, wrong level)
- **Initial analysis missed** that 3 organism tests were hitting ace-core through dependency chain
- **test_helper.rb stub** using prepend module didn't resolve the slowness

## Key Learnings

- **Unit tests must not depend on external services** - git CLI, network calls, or filesystem searches
- **Test profiling is essential** - `ace-test --profile 10` immediately showed 3 tests taking 1-2s each
- **Cross-package dependencies matter** - ace-core ConfigResolver impacts ace-git test performance
- **Stub at the right level** - stubbing user_config in ace-git wasn't enough, ConfigResolver is deeper
- **Separate concerns** - ace-git tests shouldn't test ace-core functionality
- **Iterative investigation** - profiling → fix → profile again revealed new bottlenecks

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Slow organism tests** (3 tests at 1.7-2s each)
  - Occurrences: Identified after atoms were fixed
  - Impact: organism tests remained at ~5.7s (80% of total test time)
  - Root Cause: ace-core ConfigResolver filesystem searches through dependency chain

- **Stubbing approaches didn't work**
  - Occurrences: 3-4 different stub attempts (stub before require, prepend module, method override)
  - Impact: Wasted time on non-solutions
  - Root Cause: ConfigResolver called deep in dependency chain, not at ace-git level

#### Medium Impact Issues

- **User correction on test scope**
  - User insight: "still why do we have to run 3 tests that depend on not our code?"
  - Refocused effort from stubbing individual tests to identifying cross-package dependency
  - Led to creating Task 156 for ace-core fix

#### Low Impact Issues

- **Test helper modifications**
  - Removing reset_config! didn't help (saved ~0.1s)
  - Stubbing user_config via prepend didn't help

### Improvement Proposals

#### Process Improvements

- **Profile-first approach**: Always run with --profile before optimizing to identify actual bottlenecks
- **Test dependency mapping**: Document which external services each test calls (git, network, filesystem)

#### Tool Enhancements

- **ace-taskflow task 156**: Create ConfigResolver test mode for ace-core
- **Test helper stub**: Standard pattern for stubbing ace-core dependencies in test helpers

#### Communication Protocols

- **Clarify test boundaries**: User correctly identified that tests shouldn't depend on external code

### Token Limit & Truncation Issues

- **No significant issues** - conversation stayed focused and linear
- **Test profiling output** was concise and actionable

## Action Items

### Stop Doing

- Running real git commands in unit tests (use stubs instead)
- Calling external services (gh CLI, network) in unit tests
- Letting cross-package dependencies impact test performance

### Continue Doing

- Profiling tests with `--profile 10` to identify slow tests
- Stubbing at appropriate levels (CommandExecutor, molecules)
- Creating follow-up tasks for cross-package issues

### Start Doing

- Stubbing ace-core ConfigResolver in test helpers (once Task 156 is implemented)
- Reviewing test dependencies for external service calls
- Designing tests to be isolated from filesystem and network

## Technical Details

### Files Modified

1. **ace-git/lib/ace/git.rb**
   - Added `@user_config` caching to avoid repeated ace-core ConfigResolver calls

2. **ace-git/test/atoms/command_executor_test.rb**
   - Stubbed `internal_execute` method
   - Replaced `sleep 10` test with Timeout stub

3. **ace-git/test/atoms/repository_checker_test.rb**
   - Stubbed `CommandExecutor.execute` for all tests

4. **ace-git/test/atoms/repository_state_detector_test.rb**
   - Stubbed `CommandExecutor.execute` and `File.exist?`

5. **ace-git/test/atoms/git_scope_filter_test.rb**
   - Removed skip-based tests, kept stubbed versions

6. **ace-git/test/test_helper.rb**
   - Added user_config stub module (attempted, didn't fully resolve slowness)

### Performance Results

| Test Group | Before | After | Improvement |
|------------|--------|-------|-------------|
| atoms (192 tests) | 11.2s | 22ms | 99.8% faster |
| molecules (79 tests) | 26ms | 19ms | 27% faster |
| organisms (29 tests) | 5.66s | 5.69s | unchanged (ace-core dependency) |
| models (69 tests) | 13ms | 16ms | similar |
| commands (44 tests) | 706ms | 708ms | similar |
| integration (23 tests) | 719ms | 725ms | similar |
| **TOTAL (439 tests)** | **~18s** | **~7.3s** | **60% faster** |

### Commits

1. `458a393f` - "feat(ace-git): Optimize git operations and cache config"
2. `b6691365` - "refactor(ace-git): Speed up unit tests by stubbing external calls and caching config"

## Additional Context

- **Branch**: `140-enhance-ace-context-with-dynamic-git-branch-and-pr-information`
- **Task 156 Created**: `.ace-taskflow/v.0.9.0/tasks/156-config-perf/156-improve-configresolver-performance-for-tests.s.md`
- **Key User Insights**:
  - "atoms and organism tests takes almost 18 seconds - and those unit tests... we should not call external services"
  - "is there is no one call that we can take recent 10 prs with metadata and the filter them appropriate"
  - "still why do we have to run 3 tests that depend on not our code? we should not test the ace-core functionality at all"
