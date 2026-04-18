---
id: 8rd.t.bzp.d
status: done
priority: medium
created_at: "2026-04-14 08:00:14"
estimate: TBD
dependencies: []
tags: [ace-llm, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-llm/docs/usage.md, .ace-local/e2e-migration/ace-llm/review.md, .ace-local/e2e-migration/ace-llm/plan.md]
  commands: [ace-task show 8rd.t.bzp.d --content]
needs_review: false
---

# Rewrite ace-llm E2E suite to public-surface goal style

## Objective

Keep the valuable `ace-llm` query flow, reduce infra brittleness, and add the missing `--output` and provider-discovery user journeys.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-llm` E2E journeys from `ace-llm/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-llm/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: `TS-LLM-001 / TC-001 basic query` - Keep core real-query journey as baseline sanity check for packaged executable + real provider response/error handling..
3. Rewrite or narrow brittle coverage identified by the plan: `TS-LLM-001 / TC-002 model selection` - Keep objective, but reduce fragility: use documented model/provider pair with broad availability at HEAD, and strengthen verifier to check concrete output semantics (json structure/content expectations) rather than only capture-file existence..
4. Add any new goal-style scenarios or test cases required by the plan: `TC-003 output-file-contract` - `TS-LLM-001-llm-query`; `TC-001 list-providers-public-surface` - `TS-LLM-002-provider-discovery`.
5. Apply the package's public-surface gap actions before treating the suite as complete: Align E2E commands with current docs examples and alias guidance; Tighten verifier oracle rubric to prioritize final output artifacts and command-intent content checks; Add explicit handling for provider-unavailable vs command-behavior failures.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-llm/docs/usage.md` remain the source of truth for the retained `ace-llm` workflows.
- `ace-test-e2e ace-llm ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-llm` is in scope only when `.ace-local/e2e-migration/ace-llm/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- The package has E2E coverage for the key missing output and discovery workflows.
- Provider/model-specific fragility is reduced without introducing fake workarounds.
- Existing useful flows stay verified through real end-state or product-output evidence.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-llm` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-llm/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Rewrite verifier expectations so final filesystem/product outputs are primary oracle; capture streams become secondary evidence only.; Refactor `TC-002` to reduce infra brittleness while preserving real model-routing and `--format json` behavior checks.; Add `--output` contract E2E coverage to validate user-facing output persistence and format semantics that are high-value and currently missing.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-llm/review.md` and `.ace-local/e2e-migration/ace-llm/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-llm ...` reruns for the retained and added scenarios.

## References

- `.ace-local/assign/8rczn4/reports/010.14-run-ace-llm.r.md`
- `.ace-local/e2e-migration/ace-llm/review.md`
- `.ace-local/e2e-migration/ace-llm/plan.md`
