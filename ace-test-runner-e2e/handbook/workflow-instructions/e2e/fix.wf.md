---
name: e2e/fix
description: Apply fixes for failing E2E scenarios using prior analysis output
allowed-tools: Read, Edit, Write, Bash, Grep, Glob
argument-hint: '[package] [test-id]'
doc-type: workflow
purpose: fix-e2e-tests workflow instruction
update:
  frequency: on-change
  last-updated: '2026-02-24'
---

# Fix E2E Tests Workflow

## Goal

Apply targeted fixes for failing E2E scenarios based on an existing E2E failure analysis report.

This workflow is execution-only. Root cause classification is handled by `wfi://e2e/analyze-failures`.

## Hard Gate (Required Before Any Fix)

Do not apply any fix until an analysis report exists with:
- scenario / TC identifier
- category (`code-issue`, `test-issue`, `runner-infrastructure-issue`)
- evidence from reports/artifacts
- fix target
- rerun scope recommendation

If analysis is missing or incomplete, stop and run:
```bash
ace-bundle wfi://e2e/analyze-failures
```

## Required Input

Use the output section from `e2e/analyze-failures`:
- `## E2E Failure Analysis Report`
- `### Execution Plan Input`

## Priority Order

Apply fixes in this order:
1. `runner-infrastructure-issue` (can unblock many scenarios)
2. `code-issue`
3. `test-issue`

## Fix Procedure

1. Pick the first prioritized item from analysis
- Use the selected "First item to fix"
- Confirm category, fix target, and rerun scope

2. Apply category-specific fix

### Category: runner-infrastructure-issue
- Fix runner/sandbox/provider/reporting/orchestration behavior
- Verify with runner tests when applicable: `ace-test ace-test-runner-e2e`

### Category: code-issue
- Fix package/tool behavior in implementation code
- Add/update unit tests if needed

### Category: test-issue
- Fix scenario definition, runner/verifier criteria, fixtures, or setup steps
- Keep implementation unchanged unless analysis is revised

3. Verify using analysis-selected rerun scope

```bash
# scenario scope (default)
ace-test-e2e {package} {test-id}

# package scope (only if analysis recommended)
ace-test-e2e {package}

# suite scope (only if analysis recommended)
ace-test-e2e-suite --only-failures
```

4. Re-check classification when evidence conflicts
- If outcome contradicts analysis, return to `e2e/analyze-failures`
- Update analysis report before continuing

5. Iterate until all targeted failures are resolved
- Keep one active scenario/TC at a time
- Preserve cost-conscious rerun discipline

## Cost-Conscious Rules

- Do not run suite-level tests by default
- Prefer scenario reruns while iterating
- Use package/suite reruns only when analysis explicitly recommends broader scope

## Required Output

```markdown
## E2E Fix Execution Summary

| Scenario / TC | Category | Change Applied | Verification Command | Result |
|---|---|---|---|---|
| ... | ... | ... | ... | pass/fail |
```

If unresolved:

```markdown
## Blockers
- Scenario / TC: ...
- Why unresolved: ...
- New evidence: ...
- Re-analysis required: yes/no
```

## Success Criteria

- Fixes are traceable to analyzed failures
- Verification scope matches analysis recommendation
- Cost-conscious rerun strategy was followed
- Targeted failures pass, or blockers are explicitly documented
