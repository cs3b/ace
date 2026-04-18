---
id: 8rd.t.bzp.a
status: done
priority: medium
created_at: "2026-04-14 08:00:14"
estimate: TBD
dependencies: []
tags: [ace-handbook, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-handbook/docs/usage.md, .ace-local/e2e-migration/ace-handbook/review.md, .ace-local/e2e-migration/ace-handbook/plan.md]
  commands: [ace-task show 8rd.t.bzp.a --content]
needs_review: false
---

# Rewrite ace-handbook E2E suite to public-surface goal style

## Objective

Keep the healthy `ace-handbook` surface smoke and add the missing `sync` and provider-error workflows that matter for real users.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-handbook` E2E journeys from `ace-handbook/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-handbook/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TC-001 help surface - Keep as package wiring smoke check for public CLI surface.; TC-002 status table - Keep as end-user tabular contract check with real binary invocation.; TC-003 status json - Keep as machine-readable contract check from real CLI execution..
3. Rewrite or narrow brittle coverage identified by the plan: TC-002 status table - Strengthen verifier oracle ordering text to explicitly prioritize user-visible status output as product output before fallback debug artifacts.; TC-003 status json - Add stricter JSON shape assertions in verifier (e.g., canonical total numeric and providers array present) while staying on public output only..
4. Add any new goal-style scenarios or test cases required by the plan: `TC-001 sync-provider-projection` - `TS-HANDBOOK-002-sync-behavior`; `TC-002 status-unknown-provider-error` - `TS-HANDBOOK-002-sync-behavior`.
5. Apply the package's public-surface gap actions before treating the suite as complete.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-handbook/docs/usage.md` remain the source of truth for the retained `ace-handbook` workflows.
- `ace-test-e2e ace-handbook ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-handbook` is in scope only when `.ace-local/e2e-migration/ace-handbook/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- `ace-handbook sync --provider` has real E2E coverage.
- Provider error semantics are represented as public CLI behavior.
- Status checks stay goal-style and low-friction.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-handbook` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-handbook/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Add the new sync-behavior scenario first, because `sync` is the core filesystem-impact command and currently has no E2E coverage.; Tighten status verifier checks (especially JSON structure) without introducing hidden-recipe or helper-artifact coupling.; Align docs/help wording with the exact public invocation paths that runners use, so scenarios remain goal-driven and self-serve.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-handbook/review.md` and `.ace-local/e2e-migration/ace-handbook/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-handbook ...` reruns for the retained and new scenarios.

## References

- `.ace-local/assign/8rczn4/reports/010.11-run-ace-handbook.r.md`
- `.ace-local/e2e-migration/ace-handbook/review.md`
- `.ace-local/e2e-migration/ace-handbook/plan.md`
