---
id: 8rd.t.bzp.l
status: done
priority: medium
created_at: "2026-04-14 08:00:14"
estimate: TBD
dependencies: []
tags: [ace-sim, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-sim/docs/usage.md, .ace-local/e2e-migration/ace-sim/review.md, .ace-local/e2e-migration/ace-sim/plan.md]
  commands: [ace-task show 8rd.t.bzp.l --content]
needs_review: false
---

# Rewrite ace-sim E2E suite to public-surface goal style

## Objective

Rewrite `ace-sim` to remove placeholder fallback behavior, reduce provider-dependent noise, and keep only the E2E value that belongs at this layer.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-sim` E2E journeys from `ace-sim/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-sim/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TC-001-help-survey - Strong public-surface and low-friction smoke of user-visible CLI surface.; TC-005-validate-task-preset - Retain real preset run coverage; keep focus on user-visible task flow + final-stage recording..
3. Rewrite or narrow brittle coverage identified by the plan: TC-002-preset-contract - Keep validate-idea run but reduce brittle internal-tree assertions; prioritize documented outputs (`session.yml`, `synthesis.yml`, final status, key chain continuity).; TC-003-run-chain-artifacts - Remove placeholder fallback behavior; require real final-state evidence for success path and explicit recorded-failure evidence for failure path without synthetic artifacts..
4. Add any new goal-style scenarios or test cases required by the plan: Dry-run public contract (`--dry-run`) - `TS-SIM-002-public-contracts`.
5. Apply the package's public-surface gap actions before treating the suite as complete: Clarify synthesis failure-path guarantees and expected artifact set in docs; Clarify dry-run contract and observable outputs in docs/help.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-sim/docs/usage.md` remain the source of truth for the retained `ace-sim` workflows.
- `ace-test-e2e ace-sim ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-sim` is in scope only when `.ace-local/e2e-migration/ace-sim/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- Placeholder or fallback-based passing behavior is gone.
- The scenario set is smaller, clearer, and less provider-friction-heavy.
- Real synthesis/dry-run behavior remains covered where it has true E2E value.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-sim` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-sim/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Remove placeholder artifact synthesis fallback in current TC-003/TC-004 paths.; Consolidate synthesis behavior checks into a single goal-style TC with clear primary oracle.; Delete TC-006 after confirming fast-test guard coverage remains green.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-sim/review.md` and `.ace-local/e2e-migration/ace-sim/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-sim ...` reruns for the rewritten scenario set.

## References

- `.ace-local/assign/8rczn4/reports/010.22-run-ace-sim.r.md`
- `.ace-local/e2e-migration/ace-sim/review.md`
- `.ace-local/e2e-migration/ace-sim/plan.md`
