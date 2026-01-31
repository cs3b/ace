---
name: test-suite-health
description: Metrics and cadence for test suite health
doc-type: guide
purpose: Test suite health monitoring
search_keywords:
  - test suite health
  - test metrics
  - flake rate
  - defect removal efficiency
  - performance budgets
update:
  frequency: on-change
  last-updated: '2026-01-31'
---

# Test Suite Health

Track health metrics and audit cadence to keep feedback loops fast and reliable.

## Key Metrics

| Metric | Target | Notes |
|--------|--------|-------|
| Unit test time | <10ms per test | >100ms is a bug |
| Integration test time | <100ms per test | >100ms is a bug |
| Flake rate | <1% | Investigate immediately |
| E2E duration | Seconds | Avoid minutes unless unavoidable |
| Defect Removal Efficiency | >85% | bugs caught / (bugs caught + prod) |

## Health Cadence

- **Per PR**: `ace-test --profile 10` for changed packages
- **Weekly**: profile critical packages; fix top offenders
- **Monthly**: full-suite health review
- **Quarterly**: E2E review and mock drift audit

## Common Failure Signals

- Randomly slow tests -> cache invalidation or order dependence
- Slow unit tests -> hidden IO or zombie mocks
- Flaky E2E -> unstable environments or shared resources

## Action Patterns

- Stub at outer boundary
- Pre-warm caches in test helpers
- Move real IO to E2E
- Add contract tests for external APIs
