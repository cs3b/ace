---
id: 8rd.t.bzp.n
status: done
priority: medium
created_at: "2026-04-14 08:00:14"
estimate: TBD
dependencies: []
tags: [ace-support-nav, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-support-nav/README.md, .ace-local/e2e-migration/ace-support-nav/review.md, .ace-local/e2e-migration/ace-support-nav/plan.md]
  commands: [ace-task show 8rd.t.bzp.n --content]
needs_review: false
---

# Rewrite ace-support-nav E2E suite to public-surface goal style

## Objective

Rebalance `ace-support-nav` E2E around real navigation and creation workflows rather than extension-inference internals.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-support-nav` E2E journeys from `ace-support-nav/README.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-support-nav/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TC-004 error handling - Strong user-facing contract coverage (non-zero exit, informative error, no stack trace). Retain with minor verifier wording cleanup..
3. Rewrite or narrow brittle coverage identified by the plan: TC-001 help survey - Keep as onboarding/job framing but update verifier to require actionable protocol/command discovery evidence tied to later commands executed (not only text snippets).; TC-002 extension inference chain - Narrow to one realistic user job: resolve a guide and a workflow from public CLI usage without explicit extension micromanagement; assert successful resolved targets and usability, not fallback chain internals..
4. Add any new goal-style scenarios or test cases required by the plan: TC-006 create-from-template-public-path - TS-NAV-001-resource-navigation.
5. Apply the package's public-surface gap actions before treating the suite as complete: Expand CLI help examples to include one complete user journey (`resolve` -> `list`/`sources` -> `create`); Add short docs note on expected user-facing success criteria (resolved path usability, created file result).
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-support-nav/README.md` remain the source of truth for the retained `ace-support-nav` workflows.
- `ace-test-e2e ace-support-nav ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-support-nav` is in scope only when `.ace-local/e2e-migration/ace-support-nav/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- The suite focuses on user-visible resolve/create/error behavior.
- Internal inference/priority detail is left to lower layers.
- The new creation journey exists as a real end-to-end package flow.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-support-nav` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-support-nav/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Rewrite verifier rules to make final resolved/created artifacts the primary oracle and runner observations secondary.; Consolidate extension-specific checks into one user-journey TC and delete internal-detail-only assertions.; Add creation-flow E2E to cover currently underrepresented end-to-end behavior while keeping deterministic inference mechanics in unit tests.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-support-nav/review.md` and `.ace-local/e2e-migration/ace-support-nav/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-support-nav ...` reruns for the rewritten scenario set.

## References

- `.ace-local/assign/8rczn4/reports/010.24-run-ace-support-nav.r.md`
- `.ace-local/e2e-migration/ace-support-nav/review.md`
- `.ace-local/e2e-migration/ace-support-nav/plan.md`
