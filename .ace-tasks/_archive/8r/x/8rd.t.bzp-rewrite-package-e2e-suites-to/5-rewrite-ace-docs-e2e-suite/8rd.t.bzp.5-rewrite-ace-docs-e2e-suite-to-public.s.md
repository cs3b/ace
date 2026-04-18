---
id: 8rd.t.bzp.5
status: done
priority: medium
created_at: "2026-04-14 08:00:13"
estimate: TBD
dependencies: []
tags: [ace-docs, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-docs/docs/usage.md, .ace-local/e2e-migration/ace-docs/review.md, .ace-local/e2e-migration/ace-docs/plan.md]
  commands: [ace-task show 8rd.t.bzp.5 --content]
needs_review: false
---

# Rewrite ace-docs E2E suite to public-surface goal style

## Objective

Shift `ace-docs` E2E from stdout-driven checks toward durable artifact/state verification and add the missing analysis workflows.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-docs` E2E journeys from `ace-docs/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-docs/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TC-004 update docs - Keep core job and filesystem before/after oracle; this is high-value E2E proof of CLI mutation behavior..
3. Rewrite or narrow brittle coverage identified by the plan: TC-001 discover docs - Keep command, but strengthen verifier toward deterministic project-state evidence and reduce pure keyword checks.; TC-002 validate docs - Keep command, reduce output-format coupling; assert meaningful validation outcomes with stable evidence categories.; TC-003 status check - Keep command, reduce fragile summary-string matching and assert stable status semantics for seeded docs..
4. Add any new goal-style scenarios or test cases required by the plan: `TC-005 analyze-doc-drift` - `TS-DOCS-002-analysis-workflows`; `TC-006 analyze-consistency-report` - `TS-DOCS-002-analysis-workflows`.
5. Apply the package's public-surface gap actions before treating the suite as complete: Add explicit usage examples for deterministic `analyze`/`analyze-consistency` testable flows (fixtures, scope, expected artifacts); Ensure `--help` output for analysis commands clearly communicates required inputs and output/report locations.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-docs/docs/usage.md` remain the source of truth for the retained `ace-docs` workflows.
- `ace-test-e2e ace-docs ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-docs` is in scope only when `.ace-local/e2e-migration/ace-docs/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- Existing retained TCs no longer depend mainly on output keyword matching.
- `ace-docs analyze` and `ace-docs analyze-consistency` are covered as real E2E jobs.
- Scenario setup is compatible with docs/help-first runner behavior.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-docs` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-docs/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Rewrite verifier criteria in TS-DOCS-001 so final sandbox state and durable artifacts are primary, stdout keyword checks are secondary.; Add TS-DOCS-002 to close E2E gaps for `analyze` and `analyze-consistency` user jobs.; Refactor setup assumptions to remove hidden harness dependencies where possible and keep scenario instructions public-surface aligned.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-docs/review.md` and `.ace-local/e2e-migration/ace-docs/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-docs ...` reruns for the modified and new scenarios.

## References

- `.ace-local/assign/8rczn4/reports/010.06-run-ace-docs.r.md`
- `.ace-local/e2e-migration/ace-docs/review.md`
- `.ace-local/e2e-migration/ace-docs/plan.md`
