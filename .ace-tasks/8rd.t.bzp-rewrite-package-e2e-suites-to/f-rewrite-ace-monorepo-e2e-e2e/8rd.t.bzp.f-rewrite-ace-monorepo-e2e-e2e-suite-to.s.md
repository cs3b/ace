---
id: 8rd.t.bzp.f
status: pending
priority: medium
created_at: "2026-04-14 08:00:14"
estimate: TBD
dependencies: []
tags: [ace-monorepo-e2e, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-monorepo-e2e/README.md, .ace-local/e2e-migration/ace-monorepo-e2e/review.md, .ace-local/e2e-migration/ace-monorepo-e2e/plan.md]
  commands: [ace-task show 8rd.t.bzp.f --content]
needs_review: false
---

# Rewrite ace-monorepo-e2e E2E suite to public-surface goal style

## Objective

Rewrite the monorepo verification scenarios so they validate install and config-cascade behavior through public CLI evidence rather than harness-heavy or internal API checks.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-monorepo-e2e` E2E journeys from `ace-monorepo-e2e/README.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-monorepo-e2e/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: No mandatory in-package unit backfill for this package (scenario container by design). If future removals occur in TS-MONO-001, add deterministic checks in owning packages for any extracted pure classification or parsing logic..
3. Rewrite or narrow brittle coverage identified by the plan: No mandatory in-package unit backfill for this package (scenario container by design). If future removals occur in TS-MONO-001, add deterministic checks in owning packages for any extracted pure classification or parsing logic..
4. Add any new goal-style scenarios or test cases required by the plan: No mandatory in-package unit backfill for this package (scenario container by design). If future removals occur in TS-MONO-001, add deterministic checks in owning packages for any extracted pure classification or parsing logic..
5. Apply the package's public-surface gap actions before treating the suite as complete: Publish/refresh a public release-install verification guide that maps directly to the TS-MONO-001 user job (normal install + full-index fallback + classification meaning).; Ensure help/docs for config cascade validation include a public command-only verification path so TC-004 can avoid internal API probing.; Clarify which evidence is primary (final sandbox state / user-visible output) vs supporting telemetry in scenario contracts..
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-monorepo-e2e/README.md` remain the source of truth for the retained `ace-monorepo-e2e` workflows.
- `ace-test-e2e ace-monorepo-e2e ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-monorepo-e2e` is in scope only when `.ace-local/e2e-migration/ace-monorepo-e2e/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- Harness-heavy runner mechanics are no longer the main proof source.
- Config cascade is verified without internal Ruby resolver probing.
- The package keeps its E2E value despite minimal in-package deterministic test coverage.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-monorepo-e2e` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-monorepo-e2e/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Rewrite TS-MONO-001 TC-002/003 to reduce workaround-driven runner mechanics and anchor verdicts on end-state install outcomes.; Rewrite TS-MONO-002 TC-004 to remove unsupported internal-detail checks and use only public CLI evidence.; Tighten verifier prompts for all modified TCs so artifact existence alone cannot pass without explicit user-observable end-state evidence.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-monorepo-e2e/review.md` and `.ace-local/e2e-migration/ace-monorepo-e2e/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-monorepo-e2e ...` reruns for the rewritten scenarios.

## References

- `.ace-local/assign/8rczn4/reports/010.16-run-ace-monorepo-e2e.r.md`
- `.ace-local/e2e-migration/ace-monorepo-e2e/review.md`
- `.ace-local/e2e-migration/ace-monorepo-e2e/plan.md`
