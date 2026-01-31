---
name: test-review-checklist
description: Review checklist to validate test quality and coverage fit
doc-type: guide
purpose: Test review checklist
search_keywords:
  - test review checklist
  - test quality
  - mocking review
  - redundancy review
  - e2e review
  - behavior testing
update:
  frequency: on-change
  last-updated: '2026-01-31'
---

# Test Review Checklist

Use this checklist during code review to verify tests are meaningful, fast, and mapped to the right layer.

## Fast Loop (Unit / Mocked Integration)

- [ ] No real IO (filesystem, network, subprocess, sleep)
- [ ] Stubs occur at the **outer boundary** (avoid hidden subprocess checks)
- [ ] Tests assert **observable behavior**, not only mock calls
- [ ] Inputs/fixtures match real schema/format
- [ ] Each test has a single, clear purpose
- [ ] Runtime aligns with layer budgets (atoms <10ms, molecules <50ms, organisms <100ms)
- [ ] No unit/integration tests >100ms (violations logged)
- [ ] Zombie mock checks performed (stub targets match current code paths)

## E2E (Slow Loop)

- [ ] Exactly one E2E per major workflow (no flag permutations)
- [ ] Uses sandboxed project folder in `.cache/ace-test-e2e/`
- [ ] Real tool and API usage is documented and safe
- [ ] Cleanup steps remove created resources
- [ ] Success criteria are explicit and verifiable

## Layer Fit & Redundancy

- [ ] Each behavior tested at the **lowest viable layer**
- [ ] No duplicate tests across layers for the same behavior
- [ ] Edge cases covered in fast loop, not E2E
- [ ] Responsibility map updated if a new behavior is added

## Mock Quality

- [ ] Mock data is realistic and complete
- [ ] Stubs do not bypass the core logic being tested
- [ ] Cache resets are localized (no global side effects)

## Performance Hygiene

- [ ] `ace-test --profile 10` checked for new slow tests
- [ ] No new sleeps, subprocess calls, or network calls in unit tests
- [ ] Any slow tests documented and justified

## Minimal Approvals

- [ ] Tests are deterministic and order-independent
- [ ] Assertions use clear expected values
- [ ] Failure messages would be actionable
