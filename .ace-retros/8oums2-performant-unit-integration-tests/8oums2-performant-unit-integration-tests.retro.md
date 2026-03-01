---
id: 8oums2
title: Performant Unit and Integration Tests
type: self-review
tags: []
created_at: "2026-01-31 15:11:10"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8oums2-performant-unit-integration-tests.md
---
# Reflection: Performant Unit and Integration Tests

**Date**: 2026-01-31
**Context**: Optimizing slow test suites in ace-lint that were taking ~2-3 seconds due to subprocess calls
**Author**: Development Team
**Type**: Self-Review

## What Went Well

- Systematic profiling with `ace-test --profile 5` quickly identified the slowest tests
- Root cause analysis revealed a clear pattern: all slow tests called `system()` for availability checks
- Simple fix pattern (stubbing `available?`) was consistent across all affected tests
- Dramatic performance improvement: 2.1s → 69ms (97% reduction)

## What Could Be Improved

- Tests were written without considering subprocess overhead
- The pattern of "stub the inner method but not the outer check" was repeated in multiple files
- No performance baseline was established when tests were originally written

## Key Learnings

### 1. Subprocess Calls Are Silent Performance Killers

Tests that look fast on the surface (`Open3.stub(:capture3, ...)`) can be slow if they don't stub the **entire call chain**. In our case:

```ruby
# This stub was NOT enough:
Open3.stub(:capture3, mock_result) { runner.run("test.rb") }

# Because `run()` calls `available?` BEFORE reaching capture3:
def run(file)
  return unavailable_result unless available?  # <-- This calls system()!
  # ... then uses Open3.capture3
end
```

### 2. The Fix Pattern: Stub at the Boundary

Always stub the **outermost** method that would trigger subprocess execution:

```ruby
# CORRECT: Stub availability check to avoid subprocess
Runner.stub(:available?, true) do
  Open3.stub(:capture3, mock_result) do
    # Now the test runs fast
  end
end
```

### 3. Test Categories Have Different Performance Profiles

| Test Type | Subprocess Allowed? | Expected Duration |
|-----------|---------------------|-------------------|
| Unit (atoms) | Never | < 10ms |
| Integration (molecules) | Rarely, stub when possible | < 100ms |
| E2E (manual tests) | Yes, that's the point | Seconds |

### 4. Profiling Should Be Part of CI/PR Review

Running `ace-test --profile 5` should be standard practice when:
- Adding new tests
- Reviewing PRs that modify test files
- Periodically auditing test suite health

## Action Items

### Stop Doing

- Writing tests that call `system()` or `Open3` without stubbing
- Assuming "my test is fast" without profiling

### Continue Doing

- Using `ace-test --profile N` to identify slow tests
- Stubbing `available?` checks in runner tests
- Separating E2E tests (real subprocess) from unit tests (fully stubbed)

### Start Doing

- Add performance thresholds to CI (fail if any unit test > 100ms)
- Document the stub pattern in test helper comments
- Review existing test suites for similar subprocess leaks

## Technical Details

### The Root Cause Pattern

```ruby
# BaseRunner pattern used by StandardrbRunner, RuboCopRunner:
def self.available?
  @available ||= system_has_command?(command_name)
end

def self.system_has_command?(cmd)
  system("#{cmd} --version", out: File::NULL, err: File::NULL)  # SLOW!
end
```

### The Fix Pattern

```ruby
def test_run_includes_fix_flag_when_requested
  # Stub availability to bypass system() call
  Runner.stub(:available?, true) do
    Open3.stub(:capture3, ->(*args) { ... }) do
      Runner.run("test.rb", fix: true)
    end
  end
  assert_includes called_with, "--fix"
end
```

### Files Fixed in This Session

| File | Test | Before | After |
|------|------|--------|-------|
| standardrb_runner_test.rb | test_run_includes_fix_flag_when_requested | 0.88s | <10ms |
| rubocop_runner_test.rb | test_run_includes_autocorrect_flag_when_requested | 0.71s | <10ms |
| lint_doctor_test.rb | test_checks_pattern_coverage_with_groups | 1.55s | <10ms |
| lint_doctor_test.rb | test_warnings_accessor | 1.43s | <10ms |
| validator_registry_test.rb | test_available_validators_returns_subset_of_registered | 0.63s | <10ms |

## Additional Context

- Task: 251 - Optimize slow test suites
- Commits: `dfce715ba`, `1481b0858`
- Package: ace-lint v0.15.2
