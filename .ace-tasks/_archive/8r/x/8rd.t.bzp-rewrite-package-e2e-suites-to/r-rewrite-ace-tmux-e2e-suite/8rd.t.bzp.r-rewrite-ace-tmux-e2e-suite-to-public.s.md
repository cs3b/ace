---
id: 8rd.t.bzp.r
status: done
priority: medium
created_at: "2026-04-14 08:00:14"
estimate: TBD
dependencies: []
tags: [ace-tmux, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-tmux/docs/usage.md, .ace-local/e2e-migration/ace-tmux/review.md, .ace-local/e2e-migration/ace-tmux/plan.md]
  commands: [ace-task show 8rd.t.bzp.r --content]
needs_review: false
---

# Rewrite ace-tmux E2E suite to public-surface goal style

## Objective

Keep `ace-tmux` E2E ace-only, strengthen lifecycle oracles, and add the missing existing-session and outside-tmux user jobs.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-tmux` E2E journeys from `ace-tmux/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-tmux/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TC-001 list-presets - Core public-surface discovery step and valid E2E entrypoint..
3. Rewrite or narrow brittle coverage identified by the plan: TC-002 start-session - Tighten oracle: keep `ace-tmux`-only evidence but require explicit run-scoped outcome pattern (session name continuity across artifacts and command output). Narrow fallback branch wording so environment-constraint paths are explicit and non-ambiguous.; TC-003 add-window - Preserve no-direct-`tmux`-probe rule, but strengthen end-state evidence through `ace-tmux` output + strict target-session continuity. Explicitly separate "no window preset" vs execution failure reasons..
4. Add any new goal-style scenarios or test cases required by the plan: `TC-004 start-existing-session-behavior` - TS-TMUX-001 (or new lifecycle scenario); `TC-005 window-outside-tmux-with-session` - New `TS-TMUX-002-window-targeting`.
5. Apply the package's public-surface gap actions before treating the suite as complete: Clarify expected user-visible outputs for start/window lifecycle branches; Ensure help text examples include explicit outside-tmux `window --session` path.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-tmux/docs/usage.md` remain the source of truth for the retained `ace-tmux` workflows.
- `ace-test-e2e ace-tmux ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-tmux` is in scope only when `.ace-local/e2e-migration/ace-tmux/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- `ace-tmux` scenarios stay centered on `ace-tmux` commands rather than non-ACE probes.
- Existing-session and outside-tmux window-targeting behavior are covered.
- Lifecycle verdicts rely on public outcome evidence and runner observations.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-tmux` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-tmux/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Upgrade TC-002 and TC-003 verifiers to require stronger run-scoped outcome evidence while keeping primary-oracle rules (impact-first, runner observations second).; Add lifecycle TC for existing-session behavior (`--force` and reuse branch) to match documented CLI behavior.; Add dedicated outside-tmux window-targeting scenario so this public path is validated without hidden recipes.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-tmux/review.md` and `.ace-local/e2e-migration/ace-tmux/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-tmux ...` reruns for the rewritten scenarios.

## References

- `.ace-local/assign/8rczn4/reports/010.28-run-ace-tmux.r.md`
- `.ace-local/e2e-migration/ace-tmux/review.md`
- `.ace-local/e2e-migration/ace-tmux/plan.md`
