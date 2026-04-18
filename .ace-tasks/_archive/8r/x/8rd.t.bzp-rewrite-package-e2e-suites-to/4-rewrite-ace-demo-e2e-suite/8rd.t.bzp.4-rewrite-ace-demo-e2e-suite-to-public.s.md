---
id: 8rd.t.bzp.4
status: done
priority: medium
created_at: "2026-04-14 08:00:13"
estimate: TBD
dependencies: []
tags: [ace-demo, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-demo/docs/usage.md, .ace-local/e2e-migration/ace-demo/review.md, .ace-local/e2e-migration/ace-demo/plan.md]
  commands: [ace-task show 8rd.t.bzp.4 --content]
needs_review: false
---

# Rewrite ace-demo E2E suite to public-surface goal style

## Objective

Preserve the strong `ace-demo` lifecycle smoke cases, harden the fragile dry-run and error assertions, and add the missing non-dry-run recording success path.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-demo` E2E journeys from `ace-demo/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-demo/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TC-001 help and command surface - Fast smoke guard for packaging/registry regressions; directly public CLI surface.; TC-002 create and show tape lifecycle - Highest-value end-state oracle (real filesystem transition across commands)..
3. Rewrite or narrow brittle coverage identified by the plan: TC-003 record inline dry-run preview - Narrow expectation to public contract terms from docs/help; avoid asserting string internals that can drift. Keep proving user-visible dry-run preview only.; TC-004 attach missing `--pr` validation - Keep failure semantics check, but anchor assertion to documented CLI contract wording + non-zero exit semantics, not exact phrasing beyond key guidance..
4. Add any new goal-style scenarios or test cases required by the plan: TC-005 record preset success artifact - `TS-DEMO-001-cli-smoke`.
5. Apply the package's public-surface gap actions before treating the suite as complete: Add docs-linked assertion anchors in verifier notes; Add explicit command in usage docs examples if needed for new TC-005.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-demo/docs/usage.md` remain the source of truth for the retained `ace-demo` workflows.
- `ace-test-e2e ace-demo ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-demo` is in scope only when `.ace-local/e2e-migration/ace-demo/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- The non-dry-run record success path is covered end to end.
- Existing failure and dry-run semantics are asserted on stable public behavior, not internal wording.
- No hidden recipes are introduced to make recording coverage pass.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-demo` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-demo/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Add TC-005 to close the non-dry-run recording gap with final artifact/state as primary oracle.; Update TC-003 verifier language to check stable public outcomes and avoid fragile implementation-string coupling.; Update TC-004 verifier to keep robust failure-semantic checks while minimizing brittle exact-text matching.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-demo/review.md` and `.ace-local/e2e-migration/ace-demo/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-demo ...` reruns for the retained and added TCs.

## References

- `.ace-local/assign/8rczn4/reports/010.05-run-ace-demo.r.md`
- `.ace-local/e2e-migration/ace-demo/review.md`
- `.ace-local/e2e-migration/ace-demo/plan.md`
