---
id: v.0.9.0+task.175
status: draft
priority: medium
estimate: 2h
dependencies: []
---

# Optimize ace-test-runner test performance (8s to under 5s)

## Behavioral Specification

### User Experience
- **Input**: Developer runs `ace-test ace-test-runner` to execute test suite
- **Process**: Tests execute with mocked subprocess execution and reduced Rakefile I/O
- **Output**: Full test results in <5 seconds (down from 8.25s)

### Expected Behavior
Developers experience faster test execution. Subprocess execution is mocked in unit tests. Rakefile creation is minimized.

### Success Criteria

- [ ] Test suite runs in <5 seconds (currently 8.25s)
- [ ] All 129 tests pass
- [ ] Subprocess execution mocked in unit tests
- [ ] Rakefile I/O reduced

## Objective

Reduce ace-test-runner test execution time by 40%+ (from 8s to <5s) by mocking subprocess execution and reducing temp Rakefile creation.

## Scope of Work

### Root Cause Analysis (from investigation)
- Dir.mktmpdir + Rakefile creation in rake_integration_test.rb:10-16
- Subprocess spawning overhead (~150ms per spawn)
- InProcessRunner vs Subprocess mode selection logic

### Key Files to Modify
- `ace-test-runner/test/molecules/rake_integration_test.rb:10-16` - reduce mktmpdir + Rakefile
- `ace-test-runner/lib/ace/test_runner/molecules/smart_test_executor.rb:63-90` - verify mode selection

### Optimizations
1. Mock subprocess execution for unit tests
2. Reduce temp Rakefile creation in rake_integration_test.rb
3. Ensure InProcessRunner used when appropriate
4. Share Rakefile fixtures across tests where possible

## Out of Scope

- ❌ Changes to production code in ace-test-runner
- ❌ Reducing test coverage
