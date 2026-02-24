---
name: test/fix
description: Apply fixes for automated test failures using prior analysis output
allowed-tools: Read, Edit, Write, Bash, Grep, Glob
argument-hint: ''
doc-type: workflow
purpose: fix-tests workflow instruction
update:
  frequency: on-change
  last-updated: '2026-02-24'
---

# Fix Tests Workflow

## Goal

Apply targeted fixes for failing automated tests based on an existing failure analysis report.

This workflow is execution-only. Root cause classification is handled by `wfi://test/analyze-failures`.

## Hard Gate (Required Before Any Fix)

Do not apply any fix until an analysis report exists with:
- failure identifier
- category (`implementation-bug`, `test-defect`, `test-infrastructure`)
- evidence
- fix target
- confidence

If analysis is missing or incomplete, stop and run:
```bash
ace-bundle wfi://test/analyze-failures
```

## Required Input

Use the output section from `test/analyze-failures`:
- `## Failure Analysis Report`
- `### Execution Plan Input`

## Fix Procedure

1. Pick the first prioritized failure from analysis
- Use the "Primary failure to fix first" item
- Confirm category and fix target

2. Apply category-specific fix

### Category: implementation-bug
- Fix application/implementation code
- Update/add tests only as needed to capture intended behavior

### Category: test-defect
- Fix assertions, fixtures, setup, or test expectations
- Keep product code unchanged unless new contradictory evidence appears

### Category: test-infrastructure
- Fix setup/isolation/tooling/configuration issues
- Keep behavior/spec expectations unchanged unless analysis is revised

3. Verify the specific fix
- Run the failing test(s) first
- Run related tests second

4. Re-check classification if verification contradicts analysis
- If new evidence invalidates original category, return to `test/analyze-failures`
- Update analysis report before continuing

5. Iterate until failures are resolved
- Fix one prioritized failure at a time
- Keep changes scoped to the active failure

## Verification Sequence

```bash
# targeted failure
# Run project-specific test command path/to/failing_test

# related tests
# Run project-specific test command --related path/to/failing_test

# full suite final check
# Run project-specific test command
```

## Required Output

```markdown
## Fix Execution Summary

| Failure | Category | Change Applied | Verification | Result |
|---|---|---|---|---|
| ... | ... | ... | command + output summary | pass/fail |
```

If unresolved:

```markdown
## Blockers
- Failure: ...
- Why unresolved: ...
- New evidence: ...
- Re-analysis required: yes/no
```

## Success Criteria

- Fixes are traceable to analyzed failures
- Verification commands and outcomes are documented
- No speculative fixes outside analyzed scope
- Full test suite passes (or unresolved blockers are explicitly documented)
