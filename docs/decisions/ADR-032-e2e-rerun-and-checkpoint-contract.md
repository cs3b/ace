# ADR-032: E2E Rerun and Checkpoint Contract

## Status

Accepted
Date: 2026-03-13

## Context

Recent E2E workflow changes tightened the definition of "fix complete" for failing end-to-end scenarios. The repository now distinguishes between analysis, scoped reruns, and final suite-level verification instead of allowing one broad rerun or a code-only completion signal.

This contract now appears in workflow updates, skill metadata, suite orchestration, and failure reporting:

- `e2e/fix` now requires rerunning the selected failing scope after each fix iteration
- `--only-failures` behavior was aligned around scenario-level reruns rather than package-wide retries
- final failure-surface verification is required before concluding a fix session
- report and subprocess parsing changes preserve the evidence needed to understand what actually passed or failed

Without a written ADR, future workflow edits could relax rerun discipline, broaden rerun scope unnecessarily, or mark a fix complete without verifying the remaining failure surface.

## Decision

We will treat rerun discipline and final failure-surface verification as part of the E2E fix contract.

Key aspects of this decision:

- After each fix iteration, rerun the selected failing scope before doing more work or declaring success.
- The default rerun scope is scenario-level when the failure surface can be isolated at that level; package-wide reruns are not the default fallback.
- A fix session is not complete until a final failure-surface verification step runs against the remaining failing set, typically through `ace-test-e2e-suite --only-failures`.
- Workflow/reporting artifacts must preserve enough evidence to show what scope was rerun and what the final verification surface contained.
- Analysis and execution remain distinct phases: reruns validate a chosen fix path, but they do not replace prior failure analysis.

## Consequences

### Positive

- E2E fixes are verified incrementally instead of relying on one late rerun.
- Scenario-level reruns reduce cost and time when failures are localized.
- Final verification provides a clean operational stop condition for E2E fix work.
- Preserved reports and subprocess output make post-failure diagnosis more trustworthy.

### Negative

- Fix loops can take more steps because each iteration requires an immediate rerun.
- Workflow authors and operators must preserve scope discipline rather than defaulting to broad reruns.
- Completion is stricter; code changes alone are no longer enough to close a failing E2E task.

### Neutral

- Full-suite reruns still exist; this ADR only says they are not the default proof step for each intermediate fix iteration.
- The contract applies to E2E fix flows and related verification workflows, not every automated test command in the repo.

## Alternatives Considered

### Alternative 1: One final rerun at the end of the fix session

- **Description**: Make changes freely and rerun only once before closing.
- **Pros**: Fewer command invocations.
- **Cons**: Poor signal on which change fixed or regressed the scenario and weaker recovery behavior.
- **Why not chosen**: The repository now explicitly requires reruns after each fix iteration.

### Alternative 2: Package-wide reruns as the default scope

- **Description**: Always rerun the entire package or suite regardless of isolated failure scope.
- **Pros**: Broader coverage.
- **Cons**: Higher cost, slower feedback, and less precise operational evidence.
- **Why not chosen**: Current suite behavior and workflow guidance standardize scenario-level reruns for localized failures.

### Alternative 3: Manual review of code changes as sufficient proof

- **Description**: Allow human judgment to conclude a fix without final rerun checkpoints.
- **Pros**: Fastest workflow when infrastructure is expensive.
- **Cons**: Unverifiable completion and stale-failure risk.
- **Why not chosen**: E2E fix completion now requires rerun evidence and final failure-surface verification.

## Related Decisions

- [ADR-001: Workflow Self-Containment Principle](ADR-001-workflow-self-containment-principle.md)
- [ADR-017: Flat Test Structure](ADR-017-flat-test-structure.md)

## References

- `CHANGELOG.md`
- `ace-test-runner-e2e/CHANGELOG.md`
- `ace-test-runner-e2e/handbook/workflow-instructions/e2e/fix.wf.md`
- `ace-test-runner-e2e/handbook/skills/as-e2e-fix/SKILL.md`
