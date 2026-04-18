---
id: 8rd.t.bzp.2
status: done
priority: medium
created_at: "2026-04-14 08:00:11"
estimate: TBD
dependencies: []
tags: [ace-bundle, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-bundle/docs/usage.md, .ace-local/e2e-migration/ace-bundle/review.md, .ace-local/e2e-migration/ace-bundle/plan.md]
  commands: [ace-task show 8rd.t.bzp.2 --content]
needs_review: false
---

# Rewrite ace-bundle E2E suite to public-surface goal style

## Objective

De-risk `ace-bundle` E2E by removing internal-threshold and fixture-shortcut assumptions while keeping the real bundle-loading and output-routing user jobs.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-bundle` E2E journeys from `ace-bundle/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-bundle/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TC-001 help-survey - Keeps clear user job: discover CLI capabilities via `--help`; minimal overlap risk and low friction.; TC-002 preset-loading - Preserves strongest real-user value path (load real presets, verify output content and exits)..
3. Rewrite or narrow brittle coverage identified by the plan: TC-004 auto-format - Keep routing validation, but remove hard-coded internal-threshold contract language; assert user-visible behavior only (`stdio` vs cache messaging and explicit `--output` contract).; TC-005 cli-api-parity - Rename intent to CLI output-mode consistency + error semantics; keep CLI-only framing, remove API parity residue from title/objective/report wording..
4. Add any new goal-style scenarios or test cases required by the plan: No new TC required for this migration pass. Priority is de-risking existing cases and tightening public-surface alignment..
5. Apply the package's public-surface gap actions before treating the suite as complete: Align scenario and TC naming with public CLI behavior (`cli-api-parity` -> CLI consistency/error semantics).; Remove verifier language that treats internal threshold values as stable contract.; Strengthen runner goals to require jobs discoverable from docs/help/CLI only; eliminate fixture-specific shortcuts unless directly documented..
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-bundle/docs/usage.md` remain the source of truth for the retained `ace-bundle` workflows.
- `ace-test-e2e ace-bundle ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-bundle` is in scope only when `.ace-local/e2e-migration/ace-bundle/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- The retained TCs are executable from docs/help/CLI only.
- Internal threshold semantics and fixture-specific shortcuts are gone from E2E objectives.
- Any removed overlap is intentionally covered by fast/feat as the plan requires.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-bundle` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-bundle/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Rewrite TC-004 (old auto-format) first to remove unsupported internal-detail checks and keep only public contract assertions.; Consolidate TC-003 into TC-002 to reduce overlap and fixture-driven noise.; Rename/reframe TC-005 objective and verifier language to eliminate CLI/API drift and enforce impact-first oracles.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-bundle/review.md` and `.ace-local/e2e-migration/ace-bundle/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-bundle ...` reruns for the rewritten retained scenarios.

## References

- `.ace-local/assign/8rczn4/reports/010.03-run-ace-bundle.r.md`
- `.ace-local/e2e-migration/ace-bundle/review.md`
- `.ace-local/e2e-migration/ace-bundle/plan.md`
