---
name: test-review
description: Review tests for layer fit, mock quality, and performance
allowed-tools: Read, Write, Edit, Bash
argument-hint: [paths]
doc-type: workflow
purpose: Test review using standardized checklist
update:
  frequency: on-change
  last-updated: '2026-01-31'
---

# Test Review Workflow Instruction

## Goal

Review tests to confirm they validate behavior, fit the right layer, and keep the fast loop fast.

## Prerequisites

- Changed test files identified (PR or diff)
- Knowledge of expected behavior and IO boundaries

## Steps

1. **Identify test files** affected by changes
2. **Review layer fit** (unit vs integration vs E2E)
3. **Check mocks and fixtures** for realism
4. **Check for redundant coverage**
5. **Run profiling** if needed (`ace-test --profile 10`)
6. **Flag performance issues** (unit/integration >100ms)
7. **Document findings** using the embedded checklist

## Output

Save the review checklist with actionable notes.

<documents>
  <template path="ace-test/handbook/templates/test-review-checklist.template.md"># Test Review Checklist: {{scope}}

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

## Notes

{{notes}}
</template>
</documents>
