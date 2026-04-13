---
doc-type: workflow
title: Assign Verify Test Suite Workflow
purpose: Narrow deterministic verification contract for ace-assign orchestration
ace-docs:
  last-updated: 2026-04-13
  last-checked: 2026-04-13
---

# Verify Test Suite Workflow

## Purpose

Run the deterministic verification contract used by `ace-assign`:
- package-scoped `ace-test <package> all --profile 6` for modified packages
- monorepo verification with `ace-test-suite --target all`

Do not run `ace-test-e2e` or `ace-test-e2e-suite` from this workflow.

## Steps

1. Detect whether modified files affect runnable code.
2. If changes are docs-only or otherwise non-runnable, skip with a clear reason.
3. Detect modified packages from the current diff or working tree.
4. Run `ace-test <package> all --profile 6` for each modified package.
5. Run `ace-test-suite --target all`.

## Skip Guidance

Skip only when all modified files are documentation, retrospectives, task specs, or similarly non-runnable metadata.

## Success Criteria

- All modified packages pass `ace-test <package> all --profile 6`
- `ace-test-suite --target all` passes
- No E2E commands are used as part of this step
