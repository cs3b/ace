---
id: v.0.9.0+task.169
status: in-progress
priority: medium
estimate: 3h
dependencies: []
worktree:
  branch: 169-optimize-ace-docs-test-performance-14s-to-under-5s
  path: "../ace-task.169"
  created_at: '2026-01-03 13:05:45'
  updated_at: '2026-01-03 13:05:45'
---

# Optimize ace-docs test performance (14s to under 5s)

## Behavioral Specification

### User Experience
- **Input**: Developer runs `ace-test ace-docs` to execute test suite
- **Process**: Tests execute with mocked DocumentRegistry and consistent temp dir usage
- **Output**: Full test results in <5 seconds (down from 13.97s)

### Expected Behavior
Developers experience faster test execution. DocumentRegistry filesystem discovery is mocked in unit tests. LLM stubs are consistently applied to avoid real API calls.

### Success Criteria

- [ ] Test suite runs in <5 seconds (currently 13.97s)
- [ ] All 153 tests pass
- [ ] DocumentRegistry mocked in unit tests
- [ ] LLM calls consistently stubbed

## Objective

Reduce ace-docs test execution time by 64%+ (from 14s to <5s) by mocking DocumentRegistry filesystem walks and ensuring consistent LLM stubbing.

## Scope of Work

### Root Cause Analysis (from investigation)
- DocumentRegistry.new() walks filesystem to discover documents
- Multiple Dir.mktmpdir calls (4 files)
- Some LLM validation tests may not have consistent stubs
- Raw mktmpdir instead of with_temp_dir from test-support

### Key Files to Modify
- `ace-docs/test/integration/status_command_integration_test.rb:14` - use with_temp_dir
- `ace-docs/test/organisms/document_registry_test.rb` - mock filesystem discovery
- `ace-docs/test/organisms/validator_test.rb` - verify LLM mocking consistency

### Optimizations
1. Mock DocumentRegistry.new() to skip filesystem discovery in unit tests
2. Use with_temp_dir from test-support instead of raw mktmpdir
3. Ensure LLM stubs are consistently applied
4. Reserve real filesystem access for integration tests only

## Out of Scope

- ❌ Changes to production code in ace-docs
- ❌ Reducing test coverage