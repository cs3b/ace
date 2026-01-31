# Proposed Updates to test-performance.g.md

This document describes additions to the existing `ace-test/handbook/guides/test-performance.g.md`.

## New Sections to Add

### Add after "Performance Targets" section:

```markdown
## CI Performance Gates

Integrate performance checks into your CI pipeline to catch regressions early.

### GitHub Actions Example

```yaml
# .github/workflows/test.yml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run tests with profiling
        run: |
          ace-test --profile 20 2>&1 | tee test-profile.txt

      - name: Check performance thresholds
        run: |
          # Extract tests exceeding warning threshold (100ms)
          warnings=$(grep -E "^\s+[0-9]+\.\s+" test-profile.txt | \
            awk '$NF ~ /0\.[1-9][0-9][0-9]s/ {print}' | wc -l)

          # Extract tests exceeding critical threshold (200ms)
          critical=$(grep -E "^\s+[0-9]+\.\s+" test-profile.txt | \
            awk '$NF ~ /0\.[2-9][0-9][0-9]s|[1-9]\.[0-9]+s/ {print}' | wc -l)

          if [ "$critical" -gt 0 ]; then
            echo "::error::$critical tests exceed 200ms critical threshold"
            grep -E "0\.[2-9][0-9][0-9]s|[1-9]\.[0-9]+s" test-profile.txt
            exit 1
          fi

          if [ "$warnings" -gt 5 ]; then
            echo "::warning::$warnings tests exceed 100ms warning threshold"
          fi

      - name: Upload profile artifact
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-profile
          path: test-profile.txt
```

### Pre-commit Hook

Catch performance regressions before they reach CI:

```bash
#!/bin/bash
# .git/hooks/pre-commit

changed_packages=$(git diff --cached --name-only | \
  grep "^ace-" | cut -d/ -f1 | sort -u)

for pkg in $changed_packages; do
  echo "Profiling $pkg..."

  slow=$(ace-test "$pkg" --profile 5 2>&1 | \
    grep -E "0\.[1-9][0-9][0-9]s|[1-9]\.[0-9]+s")

  if [ -n "$slow" ]; then
    echo "Warning: Slow tests detected in $pkg:"
    echo "$slow"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  fi
done
```
```

### Add after "Zombie Mocks Pattern" section:

```markdown
## Periodic Audit Schedule

Regular audits prevent performance degradation over time.

### Weekly (After Major Changes)

```bash
# Profile changed packages
ace-test <changed-package> --profile 10
```

- Check for new tests exceeding thresholds
- Verify no zombie mocks introduced
- Review any new subprocess calls in tests

### Monthly (Full Audit)

```bash
# Full monorepo profile
ace-test-suite --profile
```

- Generate health report
- Compare to previous month
- Create tasks for violations
- Update documentation if patterns changed

### Quarterly (Deep Review)

- Review all E2E tests for continued relevance
- Check mock data against real APIs (drift detection)
- Analyze escaped defects for testing gaps
- Update guides with new patterns discovered

### Audit Report Template

```markdown
# Test Performance Audit - YYYY-MM

## Summary
- Total packages: N
- Tests exceeding warning: N
- Tests exceeding critical: N

## Violations

| Package | Test | Time | Category | Action |
|---------|------|------|----------|--------|
| ace-lint | test_x | 156ms | Zombie mock | Update stub |

## Trends
- Suite time: Ns → Ns (±N%)
- Violations: N → N

## Actions
1. [ ] Fix critical violations
2. [ ] Review warnings
```
```

### Add after "Composite Test Helpers" section:

```markdown
## Cache Pre-warming

For packages with availability caches, pre-warm at test suite startup to avoid
subprocess calls on first access.

### Implementation

```ruby
# test_helper.rb - executed once when tests load

# Pre-warm availability caches
# This runs real subprocess ONCE at startup, then all tests use cached value
if ENV['ACE_TEST_PREWARM'] != 'false'
  Ace::Package::ValidatorRegistry.available?(:tool_a)
  Ace::Package::ValidatorRegistry.available?(:tool_b)
  Ace::Package::ToolRunner.available?
end
```

### Why This Works

1. Cache populated once at startup (~500ms total)
2. All subsequent tests read from cache (~0ms)
3. Tests that stub availability override the cache
4. Tests that need real check can reset cache locally

### Resetting Caches in Tests

When a test needs to verify unavailable tool behavior:

```ruby
def test_handles_unavailable_tool
  # Reset cache locally
  ToolRunner.reset_availability_cache!

  # Stub the check
  ToolRunner.stub(:system_has_command?, false) do
    # Re-populate cache with stubbed value
    ToolRunner.available?

    result = subject.run
    assert_includes result.error, "tool not found"
  end

  # After stub ends, cache is repopulated for subsequent tests
end
```
```

## Sections to Update

### Update "When to Investigate Test Performance":

Add these items:
```markdown
4. After refactoring code that tests stub
5. When CI times increase without obvious cause
6. Monthly as part of regular audit
7. Before major releases
```

### Update "Related Guides":

Add:
```markdown
- [Test Layer Decision](guide://test-layer-decision) - Where to test each behavior
- [Test Suite Health](guide://test-suite-health) - Metrics and audits
- [Verify Test Suite Workflow](wfi://verify-test-suite) - Audit workflow
- [Optimize Tests Workflow](wfi://optimize-tests) - Optimization workflow
```
