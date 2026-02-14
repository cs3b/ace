---
name: test-performance-audit
description: Template for documenting test performance audits
doc-type: template
purpose: Test performance audit
update:
  frequency: as-needed
  last-updated: '2026-01-31'
---

# Test Performance Audit: {{scope}}

**Date:** {{date}}
**Owner:** {{owner}}
**Scope:** {{packages_or_area}}
**Command:** {{command_run}}

## Threshold Policy

- Unit/Integration tests >100ms are performance bugs

## Top Slow Tests

| Rank | Test | Time | Layer | Suspected Cause | Action |
|------|------|------|-------|-----------------|--------|
| 1 | {{test_1}} | {{time_1}} | {{layer_1}} | {{cause_1}} | {{action_1}} |
| 2 | {{test_2}} | {{time_2}} | {{layer_2}} | {{cause_2}} | {{action_2}} |
| 3 | {{test_3}} | {{time_3}} | {{layer_3}} | {{cause_3}} | {{action_3}} |

## Root Cause Summary

- {{root_cause_1}}
- {{root_cause_2}}

## Zombie Mock Checks

- {{zombie_mock_1}}
- {{zombie_mock_2}}

## Proposed Fixes

- {{fix_1}}
- {{fix_2}}

## Follow-Up Tasks

- {{task_1}}
- {{task_2}}
