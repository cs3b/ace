---
name: test-plan
description: Create a test responsibility map and coverage plan
allowed-tools: Read, Write, Edit, Bash
argument-hint: [feature | package | task]
doc-type: workflow
purpose: Plan test coverage and responsibility
update:
  frequency: on-change
  last-updated: '2026-01-31'
---

# Test Plan Workflow Instruction

## Goal

Create a test responsibility map and coverage plan that balances fast-loop tests with minimal E2E coverage.

## Roles

### Test Planner (this workflow)

Focus on **what** to test and **where** to test it:
- Map behaviors to layers
- Assign risk levels
- Identify fixtures and contracts
- Prevent redundant coverage

### Test Writer (separate)

Focus on **how** to implement tests:
- Stubs at the correct boundary
- Behavior-focused assertions
- Performance limits

## Prerequisites

- Clear understanding of the feature or package
- Knowledge of primary user workflows
- Access to existing tests and E2E scenarios

## Project Context Loading

- Read and follow: `ace-bundle wfi://load-project-context`

## High-Level Plan

### Planning Steps

- [ ] Identify behaviors and workflows
- [ ] Assign risk levels
- [ ] Map behaviors to test layers
- [ ] Identify E2E candidates (one per critical workflow)
- [ ] List gaps and redundancies
- [ ] Identify external API contracts (if any)
- [ ] Capture E2E anti-patterns to avoid (flag permutations, happy-only)

### Execution Steps

- [ ] Generate a responsibility map using the embedded template
- [ ] Document the fast-loop tests to add or update
- [ ] Identify E2E tests to add or update
- [ ] Specify contract-test or snapshot sources for external APIs
- [ ] Output a clear action list

## Output

Save the test plan near the task or feature docs, or in `.ace-taskflow/.../docs/` if appropriate.

## Guidance

- Use **Test Layer Decision** criteria (unit vs integration vs E2E) for each behavior.
- Keep **one E2E per critical workflow**; put permutations and edge cases in fast-loop tests.
- For external APIs, prefer **contract tests** or recorded snapshots; reserve live calls for E2E only.

<documents>
  <template path="ace-test/handbook/templates/test-responsibility-map.template.md"># Test Responsibility Map: {{SCOPE}}

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
</template>
</documents>
