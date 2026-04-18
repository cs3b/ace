---
id: 8rd.t.bzp.6
status: done
priority: medium
created_at: "2026-04-14 08:00:13"
estimate: TBD
dependencies: []
tags: [ace-git, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-git/docs/usage.md, .ace-local/e2e-migration/ace-git/review.md, .ace-local/e2e-migration/ace-git/plan.md]
  commands: [ace-task show 8rd.t.bzp.6 --content]
needs_review: false
---

# Rewrite ace-git E2E suite to public-surface goal style

## Objective

Remove workaround-driven and setup-owned-by-runner behavior from `ace-git` E2E while keeping the real status, diff, and PR user flows.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-git` E2E journeys from `ace-git/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-git/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TC-005 diff-output-path-security - Keep intent and command target. Preserve as negative security contract test; keep rejection-message assertion.; TC-006 status-json-no-pr - Keep as deterministic local JSON contract test and stable smoke oracle..
3. Rewrite or narrow brittle coverage identified by the plan: TC-001 git-status - Move bootstrap setup out of TC runner into `scenario.yml`/fixtures. Verify status through real output contract and repo state impact first, with captures only fallback.; TC-002 git-diff - Remove tracked-file recipe from TC; use deterministic fixture/setup path. Keep focus on user-visible diff result, not setup internals.; TC-004 pr-summary - Remove fallback-to-status workaround. Split verdict paths: either explicit PR success contract or explicit no-PR failure contract for `ace-git pr` itself..
4. Add any new goal-style scenarios or test cases required by the plan: `TC-00X-help-and-range-routing` - new lightweight `TS-GIT-002-public-surface-smoke`.
5. Apply the package's public-surface gap actions before treating the suite as complete: Align runner goals with docs/help path only; Remove cross-command fallback from PR TC; Strengthen verifier oracle ordering to impact/output-first.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-git/docs/usage.md` remain the source of truth for the retained `ace-git` workflows.
- `ace-test-e2e ace-git ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-git` is in scope only when `.ace-local/e2e-migration/ace-git/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- All high-risk public-surface-drift TCs are eliminated.
- The retained scenarios are runnable from public docs/help/CLI only.
- Fallback-based PR proof is gone from the E2E contract.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-git` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-git/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Rewrite TC-004 PR flow first: remove fallback workaround and enforce single-command oracle.; Rewrite TC-001/002 runners to eliminate hidden setup recipes and move setup ownership to scenario/fixtures.; Consolidate branch-context checks with status journey and rebalance verifier checks to impact-first output evidence.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-git/review.md` and `.ace-local/e2e-migration/ace-git/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-git ...` reruns for the rewritten scenario set.

## References

- `.ace-local/assign/8rczn4/reports/010.07-run-ace-git.r.md`
- `.ace-local/e2e-migration/ace-git/review.md`
- `.ace-local/e2e-migration/ace-git/plan.md`
