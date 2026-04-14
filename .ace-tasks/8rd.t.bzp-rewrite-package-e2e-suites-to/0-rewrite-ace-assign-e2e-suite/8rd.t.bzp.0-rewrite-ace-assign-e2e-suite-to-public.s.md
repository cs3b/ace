---
id: 8rd.t.bzp.0
status: pending
priority: medium
created_at: "2026-04-14 08:00:11"
estimate: TBD
dependencies: []
tags: [ace-assign, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-assign/docs/usage.md, .ace-local/e2e-migration/ace-assign/review.md, .ace-local/e2e-migration/ace-assign/plan.md]
  commands: [ace-task show 8rd.t.bzp.0 --content]
needs_review: false
---

# Rewrite ace-assign E2E suite to public-surface goal style

## Objective

Rewrite `ace-assign` E2E around public command journeys, with hierarchy flows, lifecycle flows, and missing operations coverage aligned to the migration plan.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-assign` E2E journeys from `ace-assign/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-assign/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: `TS-ASSIGN-001/TC-001` - Keep core lifecycle objective; rewrite verifier to assert end-state and CLI-visible transitions instead of exact capture choreography.; `TS-ASSIGN-002/TC-004` - Keep scoped subtree status objective; already closest to public-surface and impact-first oracle style..
3. Rewrite or narrow brittle coverage identified by the plan: `TS-ASSIGN-001/TC-002` - Reduce strict ordered capture requirements; assert only required transition checkpoints and user-visible mode differences.; `TS-ASSIGN-002/TC-002` - Keep auto-completion goal but remove rigid filename choreography and focus on parent/ancestor terminal state + generated reports.; `TS-ASSIGN-002/TC-003` - Convert copied-step-file oracle to CLI-visible audit evidence (`status --mode full`, `step`) wherever possible; keep minimal file-read fallback only when no public surface exists..
4. Add any new goal-style scenarios or test cases required by the plan: Multi-assignment operator flow - `TS-ASSIGN-003-multi-assignment`; Fork-run delegated subtree end-to-end - `TS-ASSIGN-003-multi-assignment` or dedicated fork scenario.
5. Apply the package's public-surface gap actions before treating the suite as complete: Trim runner constraints that encode fixture-specific capture naming; Promote `help`/docs discoverability checks for scoped assignment and fork-run; Prefer status/report end state as oracle; treat debug files as fallback only.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-assign/docs/usage.md` remain the source of truth for the retained `ace-assign` workflows.
- `ace-test-e2e ace-assign ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-assign` is in scope only when `.ace-local/e2e-migration/ace-assign/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- Existing hierarchy and lifecycle TCs follow end-state-first, no-workaround execution.
- The package implements the plan's `KEEP / MODIFY / CONSOLIDATE / ADD` decisions.
- The new operations coverage exists for the user-significant flows called out in the migration outputs.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-assign` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-assign/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Rewrite hierarchy tests first (largest friction reduction and overlap removal).; Rework lifecycle/fork verifiers to end-state-first contracts with minimal capture coupling.; Add operations scenario for currently unit-only user workflows (multi-assignment + fork-run).

## Validation Questions

- None. `.ace-local/e2e-migration/ace-assign/review.md` and `.ace-local/e2e-migration/ace-assign/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-assign ...` scenario reruns for the rewritten cases.
- Add any package-level backfill tests only if the plan requires overlap reduction support.

## References

- `.ace-local/assign/8rczn4/reports/010.01-run-ace-assign.r.md`
- `.ace-local/e2e-migration/ace-assign/review.md`
- `.ace-local/e2e-migration/ace-assign/plan.md`
