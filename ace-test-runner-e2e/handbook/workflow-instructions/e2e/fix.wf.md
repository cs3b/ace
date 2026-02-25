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
- fix target layer
- primary candidate files
- do-not-touch boundaries
- rerun scope recommendation

If analysis is missing or incomplete, stop and run:
```bash
ace-bundle wfi://e2e/analyze-failures
```

## Required Input

Use the output section from `e2e/analyze-failures`:
- `## E2E Failure Analysis Report`
- `## Fix Decisions`
- `### Execution Plan Input`

## Autonomy Rule

- Do not ask the user to choose fix target, category, or rerun scope.
- If analysis is incomplete, auto-complete missing decision fields via local evidence (reports, artifacts, scenario files, implementation), then proceed.
- Only stop for hard blockers (missing files/tools/permissions).

## Execution Environment Guardrail

- Do **not** run E2E commands autonomously in constrained/sandboxed agent environments.
- Treat `ace-test-e2e` and `ace-test-e2e-suite` as **user-executed verification** by default.
- Provide exact rerun commands for the user instead of executing them when environment fidelity is uncertain (missing `mise`, restricted HOME/state dirs, missing provider credentials, restricted tmux/socket access).
- Run E2E commands directly only when the user explicitly requests execution in the current environment and confirms it is properly configured.

## Priority Order

Apply fixes in this order:
1. `runner-infrastructure-issue` (can unblock many scenarios)
2. `code-issue`
3. `test-issue`

## Fix Procedure

1. Pick the first prioritized item from analysis
- Use the selected "First item to fix"
- Confirm category, fix target, and rerun scope
- Apply the "Chosen fix decision" and primary candidate files directly

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
# user executes locally
ace-test-e2e {package} {test-id}

# package scope (only if analysis recommended)
# user executes locally
ace-test-e2e {package}

# suite scope (only if analysis recommended)
# user executes locally
ace-test-e2e-suite --only-failures
```

4. Re-check classification when evidence conflicts
- If outcome contradicts analysis, return to `e2e/analyze-failures`
- Update analysis report and re-select a new autonomous chosen fix decision before continuing

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
- No user clarification was required for fix targeting/scope in normal flow
- Targeted failures pass, or blockers are explicitly documented
