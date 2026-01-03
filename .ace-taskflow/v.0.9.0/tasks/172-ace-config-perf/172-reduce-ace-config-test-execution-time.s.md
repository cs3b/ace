---
id: v.0.9.0+task.172
status: in-progress
priority: medium
estimate: 2h
dependencies: []
worktree:
  branch: 172-optimize-ace-config-test-performance-12s-to-under-5s
  path: "../ace-task.172"
  created_at: '2026-01-03 13:07:09'
  updated_at: '2026-01-03 13:07:09'
---

# Optimize ace-config test performance (12s to under 5s)

## Behavioral Specification

### User Experience
- **Input**: Developer runs `ace-test ace-config` to execute test suite
- **Process**: Performance tests run with reduced iterations while still validating behavior
- **Output**: Full test results in <5 seconds (down from 11.77s)

### Expected Behavior
Developers experience faster test execution. Performance tests use sampling instead of exhaustive iterations. Deep directory structures reduced in size.

### Success Criteria

- [ ] Test suite runs in <5 seconds (currently 11.77s)
- [ ] All 210 tests pass
- [ ] Performance tests still validate behavior (reduced iterations)
- [ ] Test fixtures use smaller structures

## Objective

Reduce ace-config test execution time by 58%+ (from 12s to <5s) by reducing loop iterations in performance tests and using smaller test fixtures.

## Scope of Work

### Root Cause Analysis (from investigation)
- Performance tests with 100-1000 iterations (performance_test.rb)
- 5-level deep directory structures for cascade tests
- 50 files created in with_many_files helper
- Multiple with_temp_config calls per test

### Key Files to Modify
- `ace-config/test/integration/performance_test.rb:15-26` - 100.times loop → 10
- `ace-config/test/integration/performance_test.rb:56-61` - 1000.times loop → 50
- `ace-config/test/integration/performance_test.rb:150-172` - 5-level → 2-level
- `ace-config/test/integration/performance_test.rb:176-187` - 50 files → 10 files

### Optimizations
1. Reduce iteration counts: 1000→50, 100→10
2. Use sampling for cascade resolution tests
3. Create smaller test fixtures (5-level→2-level, 50 files→10 files)
4. Performance tests still validate behavior with reduced data

## Out of Scope

- ❌ Changes to production code in ace-config
- ❌ Removing performance validation (just reducing iterations)