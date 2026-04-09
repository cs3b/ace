---
doc-type: workflow
title: Fix E2E Tests Workflow
purpose: fix-e2e-tests workflow instruction
ace-docs:
  last-updated: 2026-04-08
  last-checked: 2026-03-21
---

# Fix E2E Tests Workflow

## Goal

Apply targeted fixes for failing E2E scenarios based on an existing E2E failure analysis report.

This workflow is execution-only. Root cause classification is handled by `wfi://e2e/analyze-failures`.

## Hard Gate (Required Before Any Fix)

Do not apply any fix until an analysis report exists with:
- scenario / TC identifier
- report ID / canonical evidence source
- category (`code-issue`, `test-issue`, `runner-infrastructure-issue`)
- evidence from reports/artifacts
- desired behavior source
- implementation evidence path
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
- If analysis is incomplete, return to `wfi://e2e/analyze-failures` instead of guessing through missing behavior evidence.
- Only stop for hard blockers (missing files/tools/permissions).

## Execution Environment Guardrail

- Do **not** run E2E commands autonomously in constrained/sandboxed agent environments.
- Treat `ace-test-e2e` as **user-executed verification** by default.
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
- Confirm category, fix target, rerun scope, and failure identity lock
- Apply the "Chosen fix decision" and primary candidate files directly

2. Validate analysis quality before editing
- Confirm the failed TC has an explicit desired behavior source
- Confirm the failed TC has an implementation evidence path
- Confirm the active failure tuple is explicit:
  - `report_id`
  - `scenario`
  - `tc`
  - `canonical_evidence_source`
- If a `test-issue` classification lacks implementation-backed justification, stop and return to `wfi://e2e/analyze-failures`
- If a `code-issue` classification may still be explained by stale runner/verifier/setup capture, stop and refine the analysis first
- If the active tuple is missing or was derived from suite prose instead of `summary.r.md`, stop and return to `wfi://e2e/analyze-failures`

2a. Review the whole failing scenario before the first edit
- Read every `TC-*.runner.md` and `TC-*.verify.md` in the active scenario once before editing.
- Identify shared contract drift:
  - artifact naming
  - required vs optional captures
  - shared setup assumptions
  - shared state expectations
- Fix scope review is scenario-wide, even when the chosen edit remains TC-local.

3. Apply category-specific fix

### Category: runner-infrastructure-issue
- Fix runner/sandbox/provider/reporting/orchestration behavior
- Verify with runner tests when applicable: `ace-test ace-test-runner-e2e`

### Category: code-issue
- Fix package/tool behavior in implementation code
- Add/update unit tests if needed

### Category: test-issue
- Fix scenario definition, runner/verifier criteria, fixtures, or setup steps
- Preserve role split: runner is execution-only, verifier is impact-first verdict
- State which implementation evidence justifies leaving product code unchanged
- Keep implementation unchanged unless analysis is revised
- Do not respond to flaky semantic failures by upgrading the verifier model first.
- First repair brittle verifier oracles:
  - raw source strings asserted against transformed output
  - incidental wording asserted where only semantic behavior matters
- Only consider a stronger verifier model after the contract is structurally grounded and provider-pinned reruns still show ambiguity

4. Rerun the selected failing scope after each fix

After every implemented fix, rerun the analysis-selected failing scope before moving to the next item or recommending release.

```text
# scenario scope (default)
# user executes locally
ace-test-e2e {package} {test-id}

# package scope (only if analysis recommended)
# user executes locally
ace-test-e2e {package}
```

Rules:
- Scenario rerun is the default after each fix iteration.
- Use package rerun only when analysis explicitly selected package scope.
- For multiple failing scenarios, rerun each scenario explicitly.
```text
ace-test-e2e ace-assign TS-ASSIGN-001
ace-test-e2e ace-assign TS-ASSIGN-002
ace-test-e2e ace-bundle TS-BUNDLE-001
```
- Record the rerun command and result in the execution summary for every fix item.

5. Re-check classification when evidence conflicts
- If outcome contradicts analysis, return to `e2e/analyze-failures`
- Update analysis report and re-select a new autonomous chosen fix decision before continuing
- Invalidate the previous active tuple after every rerun
- If the scenario is still red, re-read the latest `summary.r.md` and bind a new `report_id / scenario / tc / canonical_evidence_source` tuple before any further edit

6. Iterate until all targeted failures are resolved
- Keep one active scenario/TC at a time
- Preserve cost-conscious rerun discipline

7. Run a final explicit failing-scenario checkpoint before concluding the fix session

After the currently targeted failures are addressed, require one final:

```bash
# user executes locally
ace-test-e2e {package} {test-id}
```

Use one explicit command per previously failing scenario to confirm no targeted failure remains in the active set before ending the fix session or recommending release.

## Cost-Conscious Rules

- Do not run suite reruns by default
- Prefer scenario reruns while iterating
- Use package reruns only when analysis explicitly recommends broader scope

## Required Output

```markdown
## E2E Fix Execution Summary

| Report ID | Scenario / TC | Canonical TC Source | Category | Change Applied | Verification Command | Result |
|---|---|---|---|---|
| ... | ... | ... | ... | ... | ... | pass/fail |
```

Include one final row for the batch checkpoint:
- Verification Command: one explicit rerun command per remaining failed scenario (`ace-test-e2e {package} {test-id}`)
- Result: `pass` or remaining failing scenarios
- If failures remain, continue the fix loop instead of treating the session as complete
- For every `test-issue` fix, add one short line naming the implementation evidence that justified leaving product code unchanged
- If a rerun changes the failed TC inside the same scenario, explicitly record:
  - previous tuple invalidated
  - new active tuple selected

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
- Every fix item was bound to an explicit failure identity tuple
- Verification scope matches analysis recommendation, including mandatory reruns after each fix
- Cost-conscious rerun strategy was followed
- `test-issue` fixes were not applied as a shortcut around implementation inspection
- Scenario-wide contract review was completed before the first edit in each red scenario
- Final explicit per-scenario rerun checkpoint for all targeted failures was completed before concluding the fix session
- No user clarification was required for fix targeting/scope in normal flow
- Targeted failures pass, or blockers are explicitly documented
