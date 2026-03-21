---
doc-type: guide
title: Test Suite Health Guide
purpose: Maintain healthy test suites through measurement and continuous improvement
ace-docs:
  last-updated: 2026-02-22
  last-checked: 2026-03-21
---

# Test Suite Health Guide

## Goal

Maintain test suites that are:
- **Fast**: Quick feedback loop for developers
- **Reliable**: No flaky tests, deterministic results
- **Effective**: Actually catch bugs before production
- **Maintainable**: Easy to update as code evolves

## Health Metrics

### Performance Metrics

| Metric | Target | Warning | Critical |
|--------|--------|---------|----------|
| Unit test (atoms) | <10ms | >50ms | >100ms |
| Unit test (molecules) | <50ms | >100ms | >200ms |
| Integration test | <500ms | >1s | >2s |
| Full package suite | <30s | >60s | >120s |
| Full monorepo suite | <5min | >10min | >20min |

**Measurement**: `ace-test --profile 20`

### Reliability Metrics

| Metric | Target | Warning | Critical |
|--------|--------|---------|----------|
| Flake rate | <1% | >2% | >5% |
| Test determinism | 100% | <99% | <95% |
| CI pass rate | >98% | <95% | <90% |

**Measurement**: Track CI runs over time, re-run suspicious tests

### Effectiveness Metrics

| Metric | Target | Interpretation |
|--------|--------|----------------|
| Defect Removal Efficiency | >85% | `bugs_caught / (bugs_caught + escaped_bugs)` |
| Code coverage (critical paths) | >80% | Focus on business logic, not getters |
| Escaped defects | Trending down | Bugs found in production |
| Mean Time to Detect | <1 day | Time from bug introduction to test failure |

**Measurement**: Track bugs in issue tracker, label with "escaped-defect"

## Periodic Audit Schedule

### Weekly: Changed Package Review

**When**: After significant changes to a package

**Actions**:
1. Run `ace-test <package> --profile 10`
2. Check for new tests exceeding thresholds
3. Verify no zombie mocks introduced

**Trigger**: PR changes >100 lines in test files

### Monthly: Full Suite Audit

**When**: First week of each month

**Actions**:
1. Run `ace-test-suite` with profiling
2. Generate health report
3. Create tasks for issues found
4. Compare metrics to previous month

**Checklist**:
- [ ] All packages under 30s
- [ ] No unit test >100ms
- [ ] No flaky tests (run 3x)
- [ ] Coverage not decreased

### Quarterly: Deep Review

**When**: End of each quarter

**Actions**:
1. Review all E2E tests for relevance
2. Check mock data for API drift
3. Analyze escaped defects pattern
4. Update testing guides if needed

**Checklist**:
- [ ] E2E tests still match user workflows
- [ ] Mock snapshots updated from real APIs
- [ ] Escaped defects analyzed, regression tests added
- [ ] Guides reflect current practices

## CI Integration

### Performance Gates

Add to `.github/workflows/test.yml`:

```yaml
- name: Run tests with profiling
  run: |
    ace-test --profile 20 2>&1 | tee test-profile.txt

- name: Check performance thresholds
  run: |
    # Extract slowest tests
    slow_tests=$(grep -E "^\s+[0-9]+\.\s+" test-profile.txt | \
      awk '$NF ~ /[0-9]+\.[1-9][0-9][0-9]s/ {print}')

    if [ -n "$slow_tests" ]; then
      echo "::warning::Tests exceeding 100ms threshold:"
      echo "$slow_tests"

      # Count critical violations (>200ms)
      critical=$(echo "$slow_tests" | awk '$NF ~ /[0-9]+\.[2-9][0-9][0-9]s|[1-9]\.[0-9]+s/ {count++} END {print count+0}')

      if [ "$critical" -gt 0 ]; then
        echo "::error::$critical tests exceed 200ms critical threshold"
        exit 1
      fi
    fi
```

### Flakiness Detection

```yaml
- name: Run tests multiple times for flakiness
  run: |
    for i in 1 2 3; do
      echo "=== Run $i ==="
      ace-test-suite --quiet || echo "FAILED_RUN_$i"
    done | tee runs.txt

    failures=$(grep -c "FAILED_RUN" runs.txt || true)
    if [ "$failures" -gt 0 ] && [ "$failures" -lt 3 ]; then
      echo "::error::Flaky tests detected ($failures/3 runs failed)"
      exit 1
    fi
```

### Coverage Tracking

```yaml
- name: Generate coverage report
  run: |
    COVERAGE=true ace-test-suite

- name: Check coverage threshold
  run: |
    coverage=$(cat coverage/coverage.json | jq '.metrics.covered_percent')
    if (( $(echo "$coverage < 80" | bc -l) )); then
      echo "::error::Coverage $coverage% below 80% threshold"
      exit 1
    fi
```

## Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash

# Get changed packages
changed_packages=$(git diff --cached --name-only | \
  grep "^ace-" | cut -d/ -f1 | sort -u)

if [ -z "$changed_packages" ]; then
  exit 0
fi

echo "Running tests for changed packages..."

for pkg in $changed_packages; do
  echo "Testing $pkg..."

  # Run with profile, fail on slow tests
  output=$(ace-test "$pkg" --profile 5 2>&1)
  status=$?

  if [ $status -ne 0 ]; then
    echo "Tests failed in $pkg"
    echo "$output"
    exit 1
  fi

  # Check for slow tests
  slow=$(echo "$output" | grep -E "[0-9]+\.[1-9][0-9][0-9]s" | head -3)
  if [ -n "$slow" ]; then
    echo "Warning: Slow tests in $pkg:"
    echo "$slow"
  fi
done

echo "All tests passed!"
```

## Troubleshooting Common Issues

### Issue: Random Test Failures

**Symptoms**: Different tests fail on different runs

**Diagnosis**:
1. Run tests 5x, note which fail
2. Check for shared mutable state
3. Look for test order dependencies

**Common Causes**:
- Cache invalidation between tests
- Global state not reset
- Time-dependent assertions

**Fix**:
- Pre-warm caches at test startup
- Reset state in setup, not teardown
- Use time stubs

### Issue: Sudden Slowdown

**Symptoms**: Test suite time increased significantly

**Diagnosis**:
1. `ace-test --profile 20` before and after
2. Compare slow test lists
3. Check for removed stubs

**Common Causes**:
- Zombie mocks (stub no longer matches code)
- New tests without proper stubbing
- Dependency upgrade with slower behavior

**Fix**:
- Update stubs to match new code paths
- Add missing stubs
- Profile dependency to identify bottleneck

### Issue: Tests Pass Locally, Fail in CI

**Symptoms**: Green locally, red in CI

**Diagnosis**:
1. Check CI environment differences
2. Look for timing-sensitive tests
3. Check for missing test dependencies

**Common Causes**:
- Different tool versions
- Network/filesystem differences
- Race conditions more visible on CI

**Fix**:
- Pin tool versions in CI
- Add explicit waits or retries
- Use mocks for environment-dependent behavior

### Issue: High Escaped Defect Rate

**Symptoms**: Bugs reaching production despite tests

**Diagnosis**:
1. Analyze escaped defects by category
2. Check if tests exist for those paths
3. Review test assertions

**Common Causes**:
- Missing edge case coverage
- Tests check implementation, not behavior
- Integration gaps (unit tests pass, system fails)

**Fix**:
- Add regression tests for each escaped defect
- Review test assertions for completeness
- Add integration/E2E tests for critical paths

## Health Report Template

Generate monthly with `/ace-test-verify-suite`:

```markdown
# Test Suite Health Report

**Date**: YYYY-MM-DD
**Packages**: N packages analyzed
**Total Tests**: N tests

## Performance Summary

| Package | Tests | Time | Slowest Test |
|---------|-------|------|--------------|
| ace-lint | 45 | 1.2s | test_complex_validation (89ms) |
| ace-git | 78 | 2.1s | test_diff_generation (156ms) |

### Threshold Violations
- [ ] ace-git: 2 tests >100ms (warning)
- [x] ace-lint: All tests <100ms

## Reliability Summary

| Metric | Value | Status |
|--------|-------|--------|
| Flake rate | 0.5% | OK |
| CI pass rate | 99.2% | OK |

### Flaky Tests Identified
- None this month

## Effectiveness Summary

| Metric | Value | Trend |
|--------|-------|-------|
| Escaped defects | 2 | Down from 4 |
| DRE | 87% | Up from 83% |

### Escaped Defects This Month
1. #456 - Config parsing edge case
2. #461 - CLI exit code mismatch

## Action Items

1. [ ] Add regression test for #456
2. [ ] Investigate slow test in ace-git
3. [ ] Update mock data for GitHub API
```

## See Also

- [Test Layer Decision](guide://test-layer-decision) - Where to test
- [Test Mocking Patterns](guide://test-mocking-patterns) - How to mock
- [Test Performance](guide://test-performance) - Optimization techniques