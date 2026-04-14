---
id: 8rd.t.bzp
status: pending
priority: medium
created_at: "2026-04-14 07:59:41"
estimate: TBD
dependencies: []
tags: [e2e, migration, public-surface]
bundle:
  presets: [project]
  files: [.ace-local/assign/8rczn4/reports/, .ace-tasks/8rd.t.bzp-rewrite-package-e2e-suites-to]
  commands: [ace-task show 8rd.t.bzp --content]
needs_review: false
---

# Rewrite package E2E suites to public-surface goal style

## Objective

Rewrite the retained package E2E suites so they prove two things at once: the tool works end to end, and a user can complete the job from docs, `--help`, and the public CLI without hidden recipes, workarounds, or helper-artifact-driven verdicts.

## Behavioral Specification

### User Experience

- A maintainer can take any child under `8rd.t.bzp`, open its package migration artifacts, and implement the rewrite without inventing missing package behavior.
- The batch stays organized by wave order, but each child remains an independent package slice that can be validated and landed on its own.
- The parent only closes after every package rewrite is complete and one final full `ace-test-e2e-suite` rerun confirms the migrated public-surface contract across the suite.

### Expected Behavior

1. This parent coordinates 28 package-scoped child tasks, one for each package with migration outputs under `.ace-local/e2e-migration/`.
2. Each child rewrites only its package slice and uses its own migration review and plan as the source of truth.
3. Child scope includes small docs/help updates when the package plan says the public E2E path is not yet self-serve from package docs or CLI help.
4. Rewritten scenarios must use final sandbox state or real product output as the primary oracle.
5. Runner observations are the only non-filesystem secondary evidence source.
6. Hidden recipes, workaround branches, direct fallback-tool probing, and helper-artifact-first verdicts are removed rather than re-encoded.
7. If a currently tested detail is not a supported public contract, the child should remove or narrow that E2E check and move deterministic coverage to fast/feat where its package plan requires it.
8. The parent is complete only after all child scopes are rewritten and the full suite has been rerun once at the end.
9. Child task specs are the package-level source of truth for implementation details; this parent coordinates sequence and completion criteria rather than duplicating each package plan.
10. Wave order is execution priority only and does not replace package-local verification or readiness gating.

### Interface Contract

- Public package entrypoints stay the source of truth for goal-style E2E behavior.
- No child may stabilize a scenario by teaching the runner a workaround or by making non-`ace-*` probing the main oracle.
- Docs/help changes are in scope only when they directly support the package's intended public execution path.
- Child task files under `8rd.t.bzp` carry the package-specific migration contract and may reference package docs/help updates when their migration plans require it.
- `ace-test-e2e-suite` is the parent-level final verification command after all child scopes land.

## Success Criteria

- [ ] All 28 child tasks under `8rd.t.bzp` are rewritten or completed package by package.
- [ ] Every child implements the package plan's `KEEP / MODIFY / REMOVE / CONSOLIDATE / ADD` decisions.
- [ ] Rewritten scenarios use end-state-first verification and runner observations as the only non-filesystem secondary evidence.
- [ ] Public-surface gap actions listed in package plans are handled where required for the retained E2E path.
- [ ] Planned fast/feat backfill for removed overlap is added in the packages that call for it.
- [ ] A final full `ace-test-e2e-suite` rerun is executed only after all child scopes land.

## Vertical Slice Decomposition

- Slice type: orchestrator with package-local child slices
- Slice outcome: all 28 retained package suites move to public-surface goal style with package-specific plans embedded in child tasks
- Execution shape: review and complete child tasks in wave order, then perform one parent-level full-suite rerun
- Parent promotion rule: this task is not ready for `pending` until every child task is itself ready for implementation

## Validation Questions

- None. The migration batch reports and package-local plan/review artifacts establish the package split, wave order, and verification model.

## Verification Plan

- Child-level verification: targeted `ace-test-e2e <package> ...` reruns plus any planned fast/feat checks.
- Parent-level verification:
  - task tree confirms all child scopes exist and are complete
  - migration outputs remain the traceable source for each child scope
  - one final full suite rerun confirms the migrated contract holds together

## Out of Scope

- Unrelated feature work not needed to make the documented public E2E path real
- Adding new workaround instructions to rescue brittle flows
- Cross-package handbook work already shipped in `ace-test-runner-e2e`

## References

- Batch assignment reports: `.ace-local/assign/8rczn4/reports/`
- Package migration plans: `.ace-local/e2e-migration/<package>/plan.md`
- Package migration reviews: `.ace-local/e2e-migration/<package>/review.md`
