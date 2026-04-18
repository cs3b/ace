---
id: 8rd.t.bzp.m
status: done
priority: medium
created_at: "2026-04-14 08:00:14"
estimate: TBD
dependencies: []
tags: [ace-support-models, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-support-models/README.md, .ace-local/e2e-migration/ace-support-models/review.md, .ace-local/e2e-migration/ace-support-models/plan.md]
  commands: [ace-task show 8rd.t.bzp.m --content]
needs_review: false
---

# Rewrite ace-support-models E2E suite to public-surface goal style

## Objective

Keep the useful cache and help flows in `ace-support-models` while removing hand-seeded internal cache recipes and simplifying invalid-filter coverage.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-support-models` E2E journeys from `ace-support-models/README.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-support-models/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TC-001 help surface for both binaries - Genuine E2E value: validates packaged executable wiring and public help discovery path for both binaries.; TC-002 cache clear lifecycle - Genuine E2E value: verifies real filesystem side-effect contract of `ace-models clear`..
3. Rewrite or narrow brittle coverage identified by the plan: TC-003 providers list/show with seeded cache - Replace handcrafted cache seeding with public setup path (`ace-models sync` using fixtureable source or documented test fixture entrypoint), then run `ace-llm-providers list/show`; TC-004 invalid filter error semantics - Remove cache seeding/setup and assert error semantics directly from command invocation.
4. Add any new goal-style scenarios or test cases required by the plan: TC-new-cache-status-after-sync - TS-MODELS-001-cli-smoke; TC-new-cache-diff-after-refresh - TS-MODELS-001-cli-smoke.
5. Apply the package's public-surface gap actions before treating the suite as complete: Align error/help text with flat command surface (`ace-models sync`, not `ace-models cache sync`); Document deterministic test fixture path for cache-dependent provider commands.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-support-models/README.md` remain the source of truth for the retained `ace-support-models` workflows.
- `ace-test-e2e ace-support-models ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-support-models` is in scope only when `.ace-local/e2e-migration/ace-support-models/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- Internal cache-shape authoring is gone from E2E.
- Invalid filter behavior is still covered through a simpler public path.
- Provider missing-cache guidance matches the retained user-facing contract.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-support-models` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-support-models/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Rewrite TC-003 setup to remove direct internal cache-shape authoring.; Simplify TC-004 to pure public invocation path with no workaround fixtures.; Update provider missing-cache messaging/docs so test instructions match user-facing CLI.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-support-models/review.md` and `.ace-local/e2e-migration/ace-support-models/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-support-models ...` reruns for the rewritten scenario.

## References

- `.ace-local/assign/8rczn4/reports/010.23-run-ace-support-models.r.md`
- `.ace-local/e2e-migration/ace-support-models/review.md`
- `.ace-local/e2e-migration/ace-support-models/plan.md`
