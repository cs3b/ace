---
id: 8rd.t.bzp.h
status: pending
priority: medium
created_at: "2026-04-14 08:00:14"
estimate: TBD
dependencies: []
tags: [ace-prompt-prep, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-prompt-prep/docs/usage.md, .ace-local/e2e-migration/ace-prompt-prep/review.md, .ace-local/e2e-migration/ace-prompt-prep/plan.md]
  commands: [ace-task show 8rd.t.bzp.h --content]
needs_review: false
---

# Rewrite ace-prompt-prep E2E suite to public-surface goal style

## Objective

Keep the strong archive-processing value in `ace-prompt-prep` and add the missing setup and task-scoped user journeys.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-prompt-prep` E2E journeys from `ace-prompt-prep/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-prompt-prep/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TS-PREP-001 / TC-001 process-and-archive - KEEP.
3. Rewrite or narrow brittle coverage identified by the plan: TS-PREP-001 / TC-002 bundle-context - MODIFY.
4. Add any new goal-style scenarios or test cases required by the plan: Setup initializes workspace from public CLI - TS-PREP-001 or new setup-focused scenario; Task-scoped processing path - TS-PREP-001 extension or new scenario.
5. Apply the package's public-surface gap actions before treating the suite as complete: Confirm and document canonical task-focused E2E user journey; Tighten expected output contract for bundle-mode user-visible success.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-prompt-prep/docs/usage.md` remain the source of truth for the retained `ace-prompt-prep` workflows.
- `ace-test-e2e ace-prompt-prep ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-prompt-prep` is in scope only when `.ace-local/e2e-migration/ace-prompt-prep/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- Bundle-context verification is stronger and still impact-first.
- `setup` and `--task` are covered as real public-surface workflows.
- Existing archive lifecycle coverage remains intact.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-prompt-prep` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-prompt-prep/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Rewrite TC-002 verifier to require stronger, specific context-expansion output evidence while preserving impact-first oracle order.; Add setup workflow E2E coverage from documented user path (`ace-prompt-prep setup`) with filesystem-state assertions as primary oracle.; Add task-scoped workflow E2E for `--task` to validate real path resolution and archive lifecycle in a realistic task context.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-prompt-prep/review.md` and `.ace-local/e2e-migration/ace-prompt-prep/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-prompt-prep ...` reruns for the rewritten scenario.

## References

- `.ace-local/assign/8rczn4/reports/010.18-run-ace-prompt-prep.r.md`
- `.ace-local/e2e-migration/ace-prompt-prep/review.md`
- `.ace-local/e2e-migration/ace-prompt-prep/plan.md`
