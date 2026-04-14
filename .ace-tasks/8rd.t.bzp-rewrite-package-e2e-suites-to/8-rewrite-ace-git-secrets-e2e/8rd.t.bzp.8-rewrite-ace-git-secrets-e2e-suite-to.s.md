---
id: 8rd.t.bzp.8
status: pending
priority: medium
created_at: "2026-04-14 08:00:13"
estimate: TBD
dependencies: []
tags: [ace-git-secrets, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-git-secrets/docs/usage.md, .ace-local/e2e-migration/ace-git-secrets/review.md, .ace-local/e2e-migration/ace-git-secrets/plan.md]
  commands: [ace-task show 8rd.t.bzp.8 --content]
needs_review: false
---

# Rewrite ace-git-secrets E2E suite to public-surface goal style

## Objective

Keep the core `ace-git-secrets` user-value flows while removing hidden-recipe drift, fixing public-surface inaccuracies, and narrowing brittle broad checks.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-git-secrets` E2E journeys from `ace-git-secrets/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-git-secrets/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TC-002 secret detection - Clear end-state oracle, direct user job, low friction.; TC-003 history persistence - Verifies critical git-history behavior users often misunderstand.; TC-008 check-release gate - Strong release-blocking behavior coverage with strict/json variants..
3. Rewrite or narrow brittle coverage identified by the plan: TC-001 help survey - Align with actual public surface: include `check-release`, remove expectation of `--whitelist` flag, require docs/help parity checks instead of ad-hoc flag guessing.; TC-004 output + filtering - Split assertions internally in TC flow: keep report-structure and whitelist validation but reduce fixture-coupling and focus on end-state impact.; TC-005 rewrite workflow - Validate `raw_value` through saved report contract (`.ace-local/git-secrets/sessions/...`) not workaround output scraping; keep dry-run HEAD invariance..
4. Add any new goal-style scenarios or test cases required by the plan: Saved-report remediation path (`scan -> revoke --scan-file -> rewrite-history --dry-run --scan-file`) - TS-SECRETS-002-remediation-path.
5. Apply the package's public-surface gap actions before treating the suite as complete: Clarify help/docs parity in E2E contract; Prefer saved-report contract language in runner instructions.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-git-secrets/docs/usage.md` remain the source of truth for the retained `ace-git-secrets` workflows.
- `ace-test-e2e ace-git-secrets ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-git-secrets` is in scope only when `.ace-local/e2e-migration/ace-git-secrets/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- Hidden-recipe/workaround patterns are removed from the package's retained E2E.
- Help survey expectations match the real public surface.
- Core release/history scan value cases stay covered.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-git-secrets` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-git-secrets/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Remove hidden-recipe/workaround patterns first (TC-006 removal, TC-005 rewrite).; Repair public-surface accuracy (TC-001 command/flag expectations).; Reduce broad multi-assertion brittleness by narrowing TC-004/007 into focused goal checks.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-git-secrets/review.md` and `.ace-local/e2e-migration/ace-git-secrets/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-git-secrets ...` reruns for the retained and rewritten cases.

## References

- `.ace-local/assign/8rczn4/reports/010.09-run-ace-git-secrets.r.md`
- `.ace-local/e2e-migration/ace-git-secrets/review.md`
- `.ace-local/e2e-migration/ace-git-secrets/plan.md`
