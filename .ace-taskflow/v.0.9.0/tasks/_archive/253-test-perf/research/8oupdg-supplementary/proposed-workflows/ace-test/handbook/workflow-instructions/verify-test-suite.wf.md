---
name: verify-test-suite
description: Verify test suite health and enforce performance budgets
allowed-tools: Read, Write, Edit, Bash
argument-hint: [package | path]
doc-type: workflow
purpose: Test suite health verification
update:
  frequency: on-change
  last-updated: '2026-01-31'
---

# Verify Test Suite Workflow Instruction

## Goal

Validate test suite health by enforcing the 100ms rule, detecting IO leaks, and tracking flake risk.

## Prerequisites

- `ace-test` available for target scope
- Understanding of layer budgets and IO boundaries

## Execution Steps

1. **Select scope** (package or full suite)
2. **Run profiling**: `ace-test --profile 10` (or targeted package)
3. **Flag threshold violations**:
   - Any unit/integration test >100ms is a bug
4. **Check for IO leaks**:
   - subprocess
   - filesystem
   - network
   - sleep/retry
5. **Check for zombie mocks** (stubs not matching current code path)
6. **Record results** using the embedded template
7. **Create follow-up tasks** for each violation

## Output

Save the verification report alongside the task or in `.ace-taskflow/.../docs/`.

<documents>
  <template path="ace-test/handbook/templates/test-suite-health.template.md"># Test Suite Health Report: {{scope}}

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
</template>
</documents>
