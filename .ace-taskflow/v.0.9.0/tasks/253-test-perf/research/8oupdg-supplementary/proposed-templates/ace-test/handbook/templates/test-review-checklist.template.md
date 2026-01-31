---
name: test-review-checklist
description: Checklist template for test review
doc-type: template
purpose: Test review checklist
update:
  frequency: as-needed
  last-updated: '2026-01-31'
---

# Test Review Checklist: {{scope}}

## Fast Loop
- [ ] No real IO (filesystem, network, subprocess, sleep)
- [ ] Stubs are at the outer boundary
- [ ] Assertions verify behavior, not just mock calls
- [ ] Inputs/fixtures reflect real schema
- [ ] Runtime fits layer budget

## E2E
- [ ] One E2E per critical workflow
- [ ] Sandbox in .cache/ace-test-e2e
- [ ] Safe API usage (test tokens, limited scopes)
- [ ] Cleanup documented

## Layer Fit
- [ ] Behavior tested at lowest viable layer
- [ ] No redundant coverage across layers
- [ ] Edge cases in fast loop, not E2E

## Performance
- [ ] `ace-test --profile 10` reviewed
- [ ] No new sleeps/subprocess/network in unit tests
- [ ] No unit/integration tests >100ms (violations logged)
- [ ] Zombie mock checks performed (stub targets match current code paths)

## Notes

{{notes}}
