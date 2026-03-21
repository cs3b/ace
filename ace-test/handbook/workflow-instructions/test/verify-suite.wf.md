---
doc-type: workflow
title: Verify Test Suite Workflow
purpose: Maintain healthy test suites through systematic verification
ace-docs:
  last-updated: 2026-02-22
  last-checked: 2026-03-21
---

# Verify Test Suite Workflow

## Purpose

Systematically audit test suite health to identify:
- Slow tests that should be optimized or moved to E2E
- Zombie mocks that don't test real behavior
- Tests at wrong layer
- Coverage gaps
- Flaky tests

## When to Use

- Monthly full audit (scheduled)
- Before major releases
- After significant refactoring
- When test suite feels "slow"
- When bugs escape to production

## Scope Levels

| Scope | Duration | What It Checks |
|-------|----------|----------------|
| quick | ~2 min | Performance profile only |
| standard | ~10 min | Performance + zombie detection + layer check |
| deep | ~30 min | All checks + coverage + flakiness |

## Workflow Steps

### Step 1: Performance Profile

Run tests with profiling:

```bash
# Single package
ace-test <package> --profile 20

# Full monorepo
ace-test-suite --profile
```

**Collect**:
- Total suite time
- Slowest 20 tests
- Tests exceeding thresholds

**Thresholds**:
| Test Type | Warning | Critical |
|-----------|---------|----------|
| Unit (atoms) | >50ms | >100ms |
| Unit (molecules) | >100ms | >200ms |
| Integration | >1s | >2s |

### Step 2: Identify Threshold Violations

Parse profile output:

```bash
# Extract tests exceeding 100ms
ace-test --profile 20 | grep -E "[0-9]+\.[1-9][0-9][0-9]s|[1-9]\.[0-9]+s"
```

For each violation, classify:

| Test | Time | Category | Action |
|------|------|----------|--------|
| test_complex_validation | 156ms | Unit | Investigate stub |
| test_cli_output_format | 890ms | Integration | Consider E2E |
| test_full_workflow | 2.3s | E2E | OK if intentional |

### Step 3: Zombie Mock Detection (standard+)

For each slow unit test, verify stubs are actually used:

```ruby
# Test methodology:
# 1. Change stub return value to something obviously wrong
# 2. Run test
# 3. If test still passes, stub is zombie

# Example check:
Runner.stub(:run, "ZOMBIE_CHECK_VALUE_12345") do
  result = subject.lint(file)
  # If result doesn't contain ZOMBIE_CHECK_VALUE, stub is zombie
end
```

**Indicators of zombie mocks**:
- Slow test with stubs that should make it fast
- Stub method name doesn't exist in current code
- Test passes regardless of stub return value

### Step 3b: Implementation Subprocess Detection

For each slow molecule test (>100ms):

1. **Identify the class under test** from the test filename:
   ```bash
   # test/molecules/feedback_extractor_test.rb tests:
   # lib/<package>/molecules/feedback_extractor.rb
   ```

2. **Search implementation for subprocess patterns**:
   ```bash
   # Search for backticks, system(), Open3, IO.popen in the source file
   grep -E '`[^`]+`|system\(|Open3\.|IO\.popen' lib/*/molecules/feedback_extractor.rb
   ```

3. **For each subprocess found**, verify it's stubbed in the test:
   - Check if test uses `stub_prompt_path`, `stub(:available?)`, or similar
   - If not stubbed → **Layer Violation: unstubbed subprocess**

**Common subprocess patterns to search for**:
| Pattern | Typical Cost | Standard Stub |
|---------|-------------|---------------|
| `` `ace-nav ...` `` | ~200ms | `stub_prompt_path(object)` |
| `` `git ...` `` | ~100ms | MockGitRepo or stub |
| `Open3.capture3` | ~150ms | Stub `:capture3` |
| `system("...")` | ~100ms | Stub `:system` |

### Step 4: Layer Classification Audit (standard+)

For each test file, verify it's at the correct layer:

**Check atoms/ tests**:
- [ ] No subprocess calls (Open3, system)
- [ ] No filesystem operations (except temp files)
- [ ] No network calls
- [ ] No git operations
- [ ] Test time <50ms each

**Check molecules/ tests**:
- [ ] Subprocess calls are stubbed:
  - [ ] Search SOURCE file for: backticks, system(), Open3, IO.popen
  - [ ] Each subprocess has corresponding stub in test
- [ ] Network calls use WebMock
- [ ] Git uses MockGitRepo or stubs
- [ ] Test time <200ms each

**Check organisms/ tests**:
- [ ] At most ONE real CLI test per file
- [ ] Integration points mocked appropriately
- [ ] Test time <1s each

**Check e2e/ tests**:
- [ ] Actually tests user workflow
- [ ] Uses real dependencies
- [ ] Has PASS/FAIL assertions

### Step 5: Coverage Analysis (deep)

Generate coverage report:

```bash
COVERAGE=true ace-test-suite
```

**Analyze**:
- Overall coverage percentage
- Coverage by package
- Uncovered critical paths
- Trend vs previous audit

**Focus areas**:
- Business logic (organisms)
- Error handling paths
- Edge cases in data processing

### Step 6: Flakiness Detection (deep)

Run tests multiple times:

```bash
for i in {1..5}; do
  ace-test-suite --quiet 2>&1 | grep -E "FAIL|ERROR" >> flaky-check.txt
done
```

**Identify**:
- Tests that fail inconsistently
- Tests with timing dependencies
- Tests with order dependencies

### Step 7: Generate Report

Compile findings into health report:

```markdown
# Test Suite Health Report

**Date**: YYYY-MM-DD
**Scope**: standard
**Packages Audited**: N

## Executive Summary

- Overall Health: [Good | Warning | Critical]
- Tests: N total, N passing
- Performance: [OK | N violations]
- Zombie Mocks: [None | N detected]

## Performance

### Threshold Violations

| Package | Test | Time | Action |
|---------|------|------|--------|
| ace-lint | test_complex_validation | 156ms | Stub subprocess |
| ace-git | test_diff_with_large_file | 1.2s | Move to E2E |

### Package Summary

| Package | Tests | Time | Status |
|---------|-------|------|--------|
| ace-lint | 45 | 1.2s | OK |
| ace-git | 78 | 8.5s | Warning |

## Zombie Mocks Detected

| Package | Test | Stub | Issue |
|---------|------|------|-------|
| ace-docs | test_change_detection | execute_git_command | Method renamed to generate |

## Layer Issues

| Package | Test | Current | Should Be |
|---------|------|---------|-----------|
| ace-lint | test_cli_verbose_flag | atoms | integration |

## Coverage (if deep)

| Package | Coverage | Trend |
|---------|----------|-------|
| ace-lint | 87% | +2% |
| ace-git | 72% | -1% |

### Uncovered Critical Paths
- ace-git: error handling in rebase
- ace-lint: doctor --fix path

## Flaky Tests (if deep)

| Package | Test | Failure Rate |
|---------|------|--------------|
| ace-git | test_concurrent_access | 20% (1/5) |

## Action Items

### Immediate (this week)
1. [ ] Fix zombie mock in ace-docs
2. [ ] Move ace-git slow test to E2E

### Short-term (this month)
3. [ ] Add stubs to ace-lint violations
4. [ ] Investigate ace-git flaky test

### Long-term (this quarter)
5. [ ] Improve coverage in ace-git error handling
```

### Step 8: Create Tasks

For critical issues, create follow-up tasks:

```bash
# Example task creation
ace-idea "Fix zombie mock in ace-docs test_change_detection"
ace-idea "Move ace-git test_diff_with_large_file to E2E"
```

## Automation

### Scheduled Audit

Add to cron or CI schedule:

```yaml
# .github/workflows/test-audit.yml
name: Monthly Test Audit
on:
  schedule:
    - cron: '0 9 1 * *'  # First of month, 9am
  workflow_dispatch:

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run audit
        run: |
          # Quick audit in CI
          ace-test-suite --profile > audit.txt
          # Post to issue or Slack
```

### Pre-merge Check

```yaml
# In PR workflow
- name: Performance regression check
  run: |
    ace-test --profile 20 > profile.txt
    if grep -E "[0-9]+\.[2-9][0-9][0-9]s|[1-9]\.[0-9]+s" profile.txt; then
      echo "::error::Performance regression detected"
      exit 1
    fi
```

## Checklist

### Quick Audit
- [ ] Run `ace-test-suite --profile`
- [ ] Identify tests >100ms
- [ ] Note critical violations

### Standard Audit
- [ ] Quick audit steps
- [ ] Check slow tests for zombie mocks
- [ ] Verify test layer classification
- [ ] Generate health report

### Deep Audit
- [ ] Standard audit steps
- [ ] Generate coverage report
- [ ] Run flakiness detection (5x)
- [ ] Compare to previous audit
- [ ] Create action item tasks

## See Also

- [Test Suite Health Guide](guide://test-suite-health)
- [Test Performance Guide](guide://test-performance)
- [Optimize Tests Workflow](wfi://test/optimize)