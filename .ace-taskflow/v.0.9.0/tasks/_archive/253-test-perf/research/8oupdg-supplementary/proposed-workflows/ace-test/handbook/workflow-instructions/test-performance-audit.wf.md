---
name: test-performance-audit
description: Profile tests and document slowest cases with fixes
allowed-tools: Read, Write, Edit, Bash
argument-hint: [package | path]
doc-type: workflow
purpose: Audit test performance and propose optimizations
update:
  frequency: on-change
  last-updated: '2026-01-31'
---

# Test Performance Audit Workflow Instruction

## Goal

Identify slow tests, classify root causes, and propose fixes that keep the fast loop fast.

**Policy**: Any unit or integration test >100ms is a performance bug.

## Prerequisites

- Test suite available via `ace-test`
- Knowledge of test layers and IO boundaries

## Project Context Loading

- Read and follow: `ace-bundle wfi://load-project-context`

## Execution Steps

1. **Select scope** (package, folder, or whole suite)
2. **Run profiling**:
   - `ace-test --profile 10` (or targeted package)
3. **Capture slowest tests** with timing data
4. **Classify root causes**:
   - subprocess
   - filesystem IO
   - network calls
   - sleep/retry
   - cache invalidation
   - zombie mocks (stubs not matching real code paths)
5. **Propose fixes**:
   - stub outer boundary
   - pre-warm caches
   - move integration to E2E
   - replace brittle mocks with behavior assertions
   - add contract tests or snapshots for external APIs
6. **Record results** using the embedded template

## Output

Save the audit report alongside the task or in `.ace-taskflow/.../docs/` for traceability.

## Verification Checklist

- [ ] Tests >100ms are classified and tracked
- [ ] IO leaks identified (subprocess/FS/network/sleep)
- [ ] Zombie mocks eliminated or updated
- [ ] E2E scope reduced to critical workflows only

<documents>
  <template path="ace-test/handbook/templates/test-performance-audit.template.md"># Test Performance Audit: {{scope}}

**Date:** {{date}}
**Owner:** {{owner}}
**Scope:** {{packages_or_area}}
**Command:** {{command_run}}

## Top Slow Tests

| Rank | Test | Time | Layer | Suspected Cause | Action |
|------|------|------|-------|-----------------|--------|
| 1 | {{test_1}} | {{time_1}} | {{layer_1}} | {{cause_1}} | {{action_1}} |
| 2 | {{test_2}} | {{time_2}} | {{layer_2}} | {{cause_2}} | {{action_2}} |
| 3 | {{test_3}} | {{time_3}} | {{layer_3}} | {{cause_3}} | {{action_3}} |

## Root Cause Summary

- {{root_cause_1}}
- {{root_cause_2}}

## Proposed Fixes

- {{fix_1}}
- {{fix_2}}

## Follow-Up Tasks

- {{task_1}}
- {{task_2}}
</template>
</documents>
