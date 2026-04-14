---
id: 8rd.t.bzp.e
status: pending
priority: medium
created_at: "2026-04-14 08:00:14"
estimate: TBD
dependencies: []
tags: [ace-llm-providers-cli, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-llm-providers-cli/README.md, .ace-local/e2e-migration/ace-llm-providers-cli/review.md, .ace-local/e2e-migration/ace-llm-providers-cli/plan.md]
  commands: [ace-task show 8rd.t.bzp.e --content]
needs_review: false
---

# Rewrite ace-llm-providers-cli E2E suite to public-surface goal style

## Objective

Preserve the useful provider CLI checks while removing hidden shim/setup recipes from both the failure and success paths.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-llm-providers-cli` E2E journeys from `ace-llm-providers-cli/README.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-llm-providers-cli/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: `TC-001-help-surface` - Directly validates public `--help` contract and exit semantics with minimal setup.
3. Rewrite or narrow brittle coverage identified by the plan: `TC-002-no-tools` - Replace custom `tools/which` shim recipe with a public-surface, deterministic environment setup that does not depend on helper-command interception. Keep oracle on final summary + exit code.; `TC-003-stubbed-tools` - Rewrite to avoid workaround-style synthetic full-provider emulation as primary path; keep a deterministic success oracle tied to user-visible CLI output with minimal, explicitly documented public setup..
4. Add any new goal-style scenarios or test cases required by the plan: `TC-004-metadata-traceability` (scenario metadata/lifecycle validation) - backlog candidate.
5. Apply the package's public-surface gap actions before treating the suite as complete: Document deterministic test harness policy for provider-discovery paths; Add explicit verification lifecycle metadata guidance (`last-verified`, verifier identity).
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-llm-providers-cli/README.md` remain the source of truth for the retained `ace-llm-providers-cli` workflows.
- `ace-test-e2e ace-llm-providers-cli ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-llm-providers-cli` is in scope only when `.ace-local/e2e-migration/ace-llm-providers-cli/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- The retained provider CLI scenario is deterministic without hidden shim recipes.
- Final CLI summary and exit semantics remain the primary oracle.
- Scenario maintenance drift is reduced where the plan calls for it.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-llm-providers-cli` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-llm-providers-cli/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Rewrite `TC-002` to remove hidden-recipe dependence while preserving deterministic failure-path oracle.; Rewrite `TC-003` to reduce workaround-driven setup and focus verifier on final user-visible output semantics.; Add lifecycle metadata conventions to scenario docs/templates to support migration traceability.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-llm-providers-cli/review.md` and `.ace-local/e2e-migration/ace-llm-providers-cli/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-llm-providers-cli ...` reruns for the retained scenario.

## References

- `.ace-local/assign/8rczn4/reports/010.15-run-ace-llm-providers-cli.r.md`
- `.ace-local/e2e-migration/ace-llm-providers-cli/review.md`
- `.ace-local/e2e-migration/ace-llm-providers-cli/plan.md`
