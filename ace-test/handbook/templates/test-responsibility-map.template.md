---
doc-type: template
title: "Test Responsibility Map: {{SCOPE}}"
purpose: Test responsibility mapping document
ace-docs:
  last-updated: 2026-02-19
  last-checked: 2026-03-21
---

# Test Responsibility Map: {{SCOPE}}

**Scope**: {{feature_or_package}}
**Owner**: {{owner}}
**Date**: {{date}}
**Status**: Draft | Review | Approved

## Summary

- Total behaviors: {{count}}
- High risk: {{high_risk_count}}
- Unit tests planned: {{unit_count}}
- Integration tests planned: {{integration_count}}
- E2E tests planned: {{e2e_count}}

## Behaviors and Coverage

| Behavior | Risk | Layer | Test File / ID | Source of Truth | Notes |
|----------|------|-------|----------------|-----------------|-------|
| {{behavior}} | High/Med/Low | Unit/Integration/E2E | {{test_file}} | {{source}} | {{notes}} |

### Layer Legend

- **Unit (atoms)**: Pure logic, no I/O, <10ms
- **Unit (molecules)**: Composed logic, stubbed I/O, <50ms
- **Integration (organisms)**: Component wiring, stubbed external, <500ms
- **E2E**: Real I/O, sandboxed, seconds

### Risk Legend

- **High**: Security, data integrity, core business, user-facing errors
- **Medium**: Important functionality, configuration, integrations
- **Low**: Logging, cosmetic, internal helpers

## Gaps Identified

Behaviors without test coverage:

- [ ] {{gap_1}}
- [ ] {{gap_2}}

## Redundancies to Remove

Tests that duplicate coverage:

- [ ] {{redundancy_1}} - covered by {{other_test}}
- [ ] {{redundancy_2}} - covered by {{other_test}}

## E2E Coverage Summary

Critical workflows requiring E2E validation:

| Workflow | E2E Test ID | Status |
|----------|-------------|--------|
| {{workflow_1}} | TS-{{AREA}}-{{NNN}} | Planned/Exists |
| {{workflow_2}} | TS-{{AREA}}-{{NNN}} | Planned/Exists |

## Fixtures and Contracts Needed

| Fixture/Contract | Purpose | Source |
|------------------|---------|--------|
| {{fixture_name}} | {{purpose}} | Real API snapshot / Schema / Manual |

## Action Items

- [ ] Create unit tests for: {{list}}
- [ ] Create integration tests for: {{list}}
- [ ] Create E2E test: TS-{{AREA}}-{{NNN}}
- [ ] Remove redundant tests: {{list}}
- [ ] Update fixtures: {{list}}

## Review Checklist

- [ ] Each behavior tested at lowest possible layer
- [ ] Critical workflows have E2E coverage
- [ ] Edge cases in fast loop, not E2E
- [ ] No duplicate tests across layers
- [ ] Source of truth identified for each behavior
- [ ] Risk levels assigned appropriately

## Notes

{{additional_notes}}