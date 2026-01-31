---
name: test-responsibility-map
description: Template for mapping behaviors to test layers
doc-type: template
purpose: Test responsibility mapping
update:
  frequency: as-needed
  last-updated: '2026-01-31'
---

# Test Responsibility Map: {{SCOPE}}

**Scope:** {{feature_or_package}}
**Owner:** {{owner}}
**Date:** {{date}}

## Behaviors and Coverage

| Behavior | Risk | Layer | Test File / ID | Source of Truth | Notes |
|----------|------|-------|----------------|-----------------|-------|
| {{behavior_1}} | {{risk_1}} | {{layer_1}} | {{test_1}} | {{source_1}} | {{notes_1}} |
| {{behavior_2}} | {{risk_2}} | {{layer_2}} | {{test_2}} | {{source_2}} | {{notes_2}} |
| {{behavior_3}} | {{risk_3}} | {{layer_3}} | {{test_3}} | {{source_3}} | {{notes_3}} |

## Gaps

- {{gap_1}}
- {{gap_2}}

## Redundancies to Remove

- {{redundancy_1}}
- {{redundancy_2}}

## E2E Coverage Summary

- {{critical_workflow_1}} -> {{e2e_test_id_1}}
- {{critical_workflow_2}} -> {{e2e_test_id_2}}

## Notes

{{notes}}
