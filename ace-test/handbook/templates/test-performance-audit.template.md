---
doc-type: template
title: Test Suite Performance Audit
purpose: Test performance audit report
ace-docs:
  last-updated: 2026-02-01
  last-checked: 2026-03-21
---

# Test Suite Performance Audit

**Date**: {{YYYY-MM-DD}}
**Scope**: {{package or "full monorepo"}}
**Auditor**: {{name}}

## Executive Summary

| Metric | Value | Status |
|--------|-------|--------|
| Total packages | {{N}} | - |
| Total tests | {{N}} | - |
| Suite time | {{N}}s | OK / Warning / Critical |
| Tests >100ms | {{N}} | OK / Warning / Critical |
| Tests >200ms | {{N}} | OK / Warning / Critical |
| Flake rate | {{N}}% | OK / Warning / Critical |

**Overall Health**: Good / Warning / Critical

## Performance Profile

### Slowest Tests (Top 20)

| # | Package | Test | Time | Category | Action |
|---|---------|------|------|----------|--------|
| 1 | {{pkg}} | {{test_name}} | {{time}}ms | Unit/Integration/E2E | Fix/Move/OK |

### Package Summary

| Package | Tests | Time | Avg | Slowest | Status |
|---------|-------|------|-----|---------|--------|
| {{pkg}} | {{N}} | {{N}}s | {{N}}ms | {{N}}ms | OK/Warning/Critical |

## Threshold Violations

### Critical (>200ms) - Must Fix

| Package | Test | Time | Root Cause | Remediation |
|---------|------|------|------------|-------------|
| {{pkg}} | {{test}} | {{N}}ms | Zombie mock / Subprocess leak / Wrong layer | {{action}} |

### Warning (100-200ms) - Should Fix

| Package | Test | Time | Root Cause | Remediation |
|---------|------|------|------------|-------------|
| {{pkg}} | {{test}} | {{N}}ms | {{cause}} | {{action}} |

## Zombie Mock Detection

Tests that passed but showed performance anomalies:

| Package | Test | Stub Target | Actual Code Path | Fix |
|---------|------|-------------|------------------|-----|
| {{pkg}} | {{test}} | {{stubbed_method}} | {{actual_method}} | Update stub to {{new_target}} |

## Layer Classification Audit

Tests potentially at wrong layer:

| Package | Test | Current Layer | Suggested Layer | Reason |
|---------|------|---------------|-----------------|--------|
| {{pkg}} | {{test}} | Integration | E2E | Uses real subprocess |
| {{pkg}} | {{test}} | Integration | Unit | No real I/O needed |

## Trend Analysis

### Compared to Previous Audit ({{previous_date}})

| Metric | Previous | Current | Change |
|--------|----------|---------|--------|
| Suite time | {{N}}s | {{N}}s | +/-{{N}}% |
| Tests >100ms | {{N}} | {{N}} | +/-{{N}} |
| Flake rate | {{N}}% | {{N}}% | +/-{{N}}% |

### Regression Sources

- {{package}}: +{{N}}s due to {{reason}}
- {{package}}: +{{N}} slow tests due to {{reason}}

## Flakiness Report

| Package | Test | Failure Rate | Cause | Fix |
|---------|------|--------------|-------|-----|
| {{pkg}} | {{test}} | {{N}}/{{N}} runs | Timing / Ordering / External | {{action}} |

## Action Items

### Immediate (This Week)

- [ ] Fix critical violations in {{package}}
- [ ] Update zombie mocks in {{package}}
- [ ] Move {{test}} to E2E layer

### Short-term (This Month)

- [ ] Address warning-level violations
- [ ] Investigate flaky tests
- [ ] Update composite helpers in {{package}}

### Long-term (This Quarter)

- [ ] Improve coverage in {{area}}
- [ ] Review E2E test relevance
- [ ] Update mock data for API drift

## Recommendations

1. {{recommendation_1}}
2. {{recommendation_2}}
3. {{recommendation_3}}

## Appendix: Commands Used

```bash
# Profile all packages
ace-test-suite --profile

# Profile specific package
ace-test {{package}} --profile 20

# Check flakiness (5 runs)
for i in {1..5}; do ace-test-suite --quiet 2>&1 | grep FAIL; done
```