---
id: 8rd.t.bzp.7
status: pending
priority: medium
created_at: "2026-04-14 08:00:13"
estimate: TBD
dependencies: []
tags: [ace-git-commit, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-git-commit/docs/usage.md, .ace-local/e2e-migration/ace-git-commit/review.md, .ace-local/e2e-migration/ace-git-commit/plan.md]
  commands: [ace-task show 8rd.t.bzp.7 --content]
needs_review: false
---

# Rewrite ace-git-commit E2E suite to public-surface goal style

## Objective

Rewrite `ace-git-commit` E2E so split and no-split workflows are publicly reproducible, then add the missing `--only-staged` user journey.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-git-commit` E2E journeys from `ace-git-commit/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-git-commit/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TC-001 help-survey - Pure public-surface check (`--help`), low friction, strong foundation for later assertions.; TC-002 basic-commit - High-value real commit creation via CLI with Git-state primary oracle.; TC-003 dry-run-and-paths - Valid integrated behavior proving no-mutation + path-scoped commit behavior..
3. Rewrite or narrow brittle coverage identified by the plan: TC-005 auto-split - Remove fixture-recipe coupling. Rewrite setup so split boundary is created through explicit documented/public config steps in-scenario; keep outcome assertions (two commits, separated scopes).; TC-006 no-split - Same public-surface rewrite as TC-005; assert one commit across both scopes after explicit `--no-split`..
4. Add any new goal-style scenarios or test cases required by the plan: `TC-007-only-staged-contract` - Existing commit-workflow scenario or new staged-policy scenario.
5. Apply the package's public-surface gap actions before treating the suite as complete: Add explicit docs section for reproducible split/no-split setup; Strengthen runtime help hints around split behavior; Add example for `--only-staged` behavior with expected Git state.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-git-commit/docs/usage.md` remain the source of truth for the retained `ace-git-commit` workflows.
- `ace-test-e2e ace-git-commit ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-git-commit` is in scope only when `.ace-local/e2e-migration/ace-git-commit/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- Split/no-split flows can be executed from the documented public surface without hidden setup assumptions.
- `--only-staged` is covered end to end.
- Git state remains the primary oracle for the commit workflows.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-git-commit` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-git-commit/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Rewrite split/no-split TCs to remove fixture-only knowledge and enforce public-surface reproducibility.; Add `--only-staged` goal-style TC with end-state-first Git index/worktree assertions.; Update docs/help text that E2E runners depend on so setup and expected outcomes are directly discoverable.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-git-commit/review.md` and `.ace-local/e2e-migration/ace-git-commit/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-git-commit ...` reruns for the rewritten scenarios.

## References

- `.ace-local/assign/8rczn4/reports/010.08-run-ace-git-commit.r.md`
- `.ace-local/e2e-migration/ace-git-commit/review.md`
- `.ace-local/e2e-migration/ace-git-commit/plan.md`
