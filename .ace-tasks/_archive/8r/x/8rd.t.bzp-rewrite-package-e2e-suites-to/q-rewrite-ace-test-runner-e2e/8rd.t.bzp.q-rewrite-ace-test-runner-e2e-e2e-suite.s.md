---
id: 8rd.t.bzp.q
status: done
priority: medium
created_at: "2026-04-14 08:00:14"
estimate: TBD
dependencies: []
tags: [ace-test-runner-e2e, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-test-runner-e2e/docs/usage.md, .ace-local/e2e-migration/ace-test-runner-e2e/review.md, .ace-local/e2e-migration/ace-test-runner-e2e/plan.md]
  commands: [ace-task show 8rd.t.bzp.q --content]
needs_review: false
---

# Rewrite ace-test-runner-e2e E2E suite to public-surface goal style

## Objective

Make `ace-test-runner-e2e` prove its highest-value public jobs: real run+verify execution, public discovery without hidden fixture plumbing, and explicit shell-helper coverage.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-test-runner-e2e` E2E journeys from `ace-test-runner-e2e/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-test-runner-e2e/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TC-002 invalid package dry-run error path - Keeps high signal for user-facing failure semantics and non-zero exit behavior..
3. Rewrite or narrow brittle coverage identified by the plan: TC-003 dry-run discovers repo scenarios - Remove hidden fixture recipe (`$ACE_E2E_SOURCE_ROOT` copy workflow) and use package-owned public path from docs/usage. Keep goal as discovery preview validation with low-friction setup.; TC-004 suite help command surface - Expand to include one practical suite invocation expectation (`--affected` or `--only-failures` dry control flow) so it validates job completion, not only help text..
4. Add any new goal-style scenarios or test cases required by the plan: TC-A: real package scenario run produces expected report tree - TS-RUNNER-002-real-exec; TC-B: verifier pass produces independent verifier output - TS-RUNNER-002-real-exec.
5. Apply the package's public-surface gap actions before treating the suite as complete: Clarify minimal public workflow for discovery scenarios (without hidden fixture copy); Document `ace-test-e2e-sh` safe usage examples tied to generated sandbox paths.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-test-runner-e2e/docs/usage.md` remain the source of truth for the retained `ace-test-runner-e2e` workflows.
- `ace-test-e2e ace-test-runner-e2e ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-test-runner-e2e` is in scope only when `.ace-local/e2e-migration/ace-test-runner-e2e/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- Hidden fixture plumbing is removed from retained discovery coverage.
- The package has a real end-to-end runner execution scenario, not just help/dry-run text checks.
- Public shell-helper behavior is explicitly covered.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-test-runner-e2e` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-test-runner-e2e/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Replace workaround-driven TC-003 setup with a fully public, docs-driven workflow.; Add real execution + verifier scenario (`TS-RUNNER-002`) with impact-first oracle on generated outputs.; Add explicit `ace-test-e2e-sh` scenario because it is public CLI surface with no current E2E coverage.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-test-runner-e2e/review.md` and `.ace-local/e2e-migration/ace-test-runner-e2e/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-test-runner-e2e ...` reruns for the rewritten scenarios.
- Run `ace-test ace-test-runner-e2e` if the package plan's overlap/backfill requires lower-layer support.

## References

- `.ace-local/assign/8rczn4/reports/010.27-run-ace-test-runner-e2e.r.md`
- `.ace-local/e2e-migration/ace-test-runner-e2e/review.md`
- `.ace-local/e2e-migration/ace-test-runner-e2e/plan.md`
