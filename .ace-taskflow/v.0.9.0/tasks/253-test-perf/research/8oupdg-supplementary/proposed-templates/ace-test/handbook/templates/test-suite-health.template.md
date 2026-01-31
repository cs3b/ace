---
name: test-suite-health
description: Template for test suite health verification
doc-type: template
purpose: Test suite health
update:
  frequency: as-needed
  last-updated: '2026-01-31'
---

# Test Suite Health Report: {{scope}}

**Date:** {{date}}
**Owner:** {{owner}}
**Scope:** {{packages_or_area}}
**Command:** {{command_run}}

## Threshold Violations (>100ms)

| Test | Time | Layer | Suspected Cause | Action |
|------|------|-------|-----------------|--------|
| {{test_1}} | {{time_1}} | {{layer_1}} | {{cause_1}} | {{action_1}} |
| {{test_2}} | {{time_2}} | {{layer_2}} | {{cause_2}} | {{action_2}} |

## IO Leak Summary

- {{io_leak_1}}
- {{io_leak_2}}

## Zombie Mock Checks

- {{zombie_mock_1}}
- {{zombie_mock_2}}

## Flake Risk Notes

- {{flake_note_1}}
- {{flake_note_2}}

## Follow-Up Tasks

- {{task_1}}
- {{task_2}}
