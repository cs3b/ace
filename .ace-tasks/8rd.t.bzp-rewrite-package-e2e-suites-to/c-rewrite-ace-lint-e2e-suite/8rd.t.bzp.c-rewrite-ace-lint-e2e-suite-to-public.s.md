---
id: 8rd.t.bzp.c
status: pending
priority: medium
created_at: "2026-04-14 08:00:14"
estimate: TBD
dependencies: []
tags: [ace-lint, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-lint/docs/usage.md, .ace-local/e2e-migration/ace-lint/review.md, .ace-local/e2e-migration/ace-lint/plan.md]
  commands: [ace-task show 8rd.t.bzp.c --content]
needs_review: false
---

# Rewrite ace-lint E2E suite to public-surface goal style

## Objective

Rebuild `ace-lint` E2E around impact-first oracles and public-surface runner goals, replacing the current helper-artifact-heavy and hidden-recipe-driven suite.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-lint` E2E journeys from `ace-lint/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-lint/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: None unchanged. All existing TCs need migration edits to align with current oracle/public-surface contract..
3. Rewrite or narrow brittle coverage identified by the plan: TC-001-help-survey - Keep discovery goal, but make primary oracle the runner observations contract + explicit public-surface mapping from docs/usage/`--help` (not ad-hoc notes file gate); TC-002-valid-lint - Validate final product output/state directly; reduce copied helper artifact dependence; TC-003-fix-mode - Keep integrated file-change proof, simplify captures, prioritize post-run state over copied intermediate files.
4. Add any new goal-style scenarios or test cases required by the plan: TC-005-batch-integrated-outcomes - TS-LINT-001; TC-008-no-report-public-contract - TS-LINT-001.
5. Apply the package's public-surface gap actions before treating the suite as complete: Document explicit config-routing path with minimal runnable example for grouped validators; Add a concise doctor troubleshooting section (healthy vs malformed YAML expectation).
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-lint/docs/usage.md` remain the source of truth for the retained `ace-lint` workflows.
- `ace-test-e2e ace-lint ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-lint` is in scope only when `.ace-local/e2e-migration/ace-lint/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- All retained `ace-lint` E2E scenarios follow the current oracle model.
- Hidden setup recipes and helper-artifact-first checks are removed.
- Planned additions and unit backfill are implemented where the package plan calls for them.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-lint` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-lint/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Rewrite oracle model across all verifier files to end-state-first + runner observations fallback; remove helper-artifact-first checks.; Rework TC-006 and TC-007 instructions to eliminate hidden recipes/workaround branches and align strictly with docs/usage/`--help` pathways.; Replace TC-005 with focused tests (batch outcome vs no-report contract) and move remaining implementation-detail checks to unit tests.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-lint/review.md` and `.ace-local/e2e-migration/ace-lint/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-lint ...` reruns and the package backfill checks from the plan.

## References

- `.ace-local/assign/8rczn4/reports/010.13-run-ace-lint.r.md`
- `.ace-local/e2e-migration/ace-lint/review.md`
- `.ace-local/e2e-migration/ace-lint/plan.md`
