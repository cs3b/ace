---
id: 8rd.t.bzp.k
status: done
priority: medium
created_at: "2026-04-14 08:00:14"
estimate: TBD
dependencies: []
tags: [ace-search, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-search/docs/usage.md, .ace-local/e2e-migration/ace-search/review.md, .ace-local/e2e-migration/ace-search/plan.md]
  commands: [ace-task show 8rd.t.bzp.k --content]
needs_review: false
---

# Rewrite ace-search E2E suite to public-surface goal style

## Objective

Rewrite `ace-search` so file, count, and JSON journeys are expressed as user-facing jobs rather than repo-internal target probes.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-search` E2E journeys from `ace-search/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-search/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TC-001-content-search - Valid goal-style baseline; executes public command directly and demonstrates real user-visible content search behavior..
3. Rewrite or narrow brittle coverage identified by the plan: TC-002-file-search - Reframe around a user-documented file-discovery job (e.g., searching within user workspace target) rather than hard-coding `$PROJECT_ROOT_PATH/ace-search`.; TC-003-count-mode - Split assertions into one clear user outcome for count/list semantics; avoid internal-path coupling and internal-code-token dependence.; TC-004-json-output - Verify JSON contract against user-facing query/data path and documented flags; remove implementation-specific token (`class Search`) coupling..
4. Add any new goal-style scenarios or test cases required by the plan: `TC-005-preset-driven-search` - TS-SEARCH-001 or new TS-SEARCH-002; `TC-006-git-scope-search` - TS-SEARCH-001 or new TS-SEARCH-002.
5. Apply the package's public-surface gap actions before treating the suite as complete: Ensure examples in docs/help map to rewritten TC objectives; Standardize verifier language on user-impact oracles.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-search/docs/usage.md` remain the source of truth for the retained `ace-search` workflows.
- `ace-test-e2e ace-search ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-search` is in scope only when `.ace-local/e2e-migration/ace-search/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- The retained `ace-search` scenarios are public-surface-first.
- Implementation-coupled search targets are removed from E2E goals.
- The suite focuses on workflow value rather than lower-layer detail overlap.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-search` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-search/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Rewrite TC-002/003/004 objectives and verifier expectations so each test is executable from docs/help/public CLI only.; Remove repository-internal, implementation-coupled search targets from E2E goals unless explicitly user-supported.; Keep E2E focused on workflow value; push deterministic format/detail checks down to `feat`/`fast` where possible.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-search/review.md` and `.ace-local/e2e-migration/ace-search/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-search ...` reruns for the rewritten scenario set.

## References

- `.ace-local/assign/8rczn4/reports/010.21-run-ace-search.r.md`
- `.ace-local/e2e-migration/ace-search/review.md`
- `.ace-local/e2e-migration/ace-search/plan.md`
