---
id: 8ro0ja
title: watch-continuation-batch-retro
type: standard
tags: []
created_at: "2026-04-25 00:21:26"
status: active
---

# watch-continuation-batch-retro

## What Went Well

- The three design subtasks stayed cleanly separated: recovery/callback rules, watch command contract, and verification coverage each landed as focused task-artifact work instead of blending into speculative implementation.
- The assignment drive loop handled the full batch end-to-end without losing state across long forked subtrees; `ace-assign status --assignment <id>@<root>` remained a reliable source of truth whenever fork terminals were quiet.
- Multi-cycle review added value even for docs-only work. The valid, fit, and shine passes each found different contract gaps, and the apply-feedback steps tightened the final task artifacts before branch finalization.
- Post-review cleanup produced a much cleaner branch history. Reorganizing the batch into `task-specs` and `retro-specs` made the final PR easier to review than the original subtree-by-subtree commit stream.

## What Could Be Improved

- Long-running review subtrees provided little terminal feedback while `review-pr` was in progress. The drive workflow was correct to trust scoped assignment status, but the operator experience still feels opaque during multi-minute review waits.
- The review preset configuration still includes a misconfigured role (`review-geminie`), which wastes part of the shine cycle before synthesis and adds noise to the final review report.
- Docs-only assignments still spend several steps proving that tests, release, docs update, and demo work are no-ops. The workflow is accurate, but the tail is heavier than necessary for artifact-only batches.
- Archiving the first subtask automatically archived the parent task family, which is correct behavior, but it means later archival steps appear redundant unless the operator already knows the task GC behavior.

## Key Learnings

- Status-first recovery is now a practical operator rule, not just a design principle. Across task execution and review subtrees, the stable signal was scoped assignment state, while PTY silence was only telemetry.
- Review cycles are most useful when they are allowed to refine task artifacts before code exists. The batch avoided premature runtime changes by using review findings to sharpen scope, failure semantics, fixture wording, and evidence ordering.
- When a branch has already been pushed and reviewed, a later commit reorganization should be expected to force the subsequent push step into `--force-with-lease`. That dependency should be treated as normal branch hygiene, not an exceptional recovery path.
- For docs/spec branches, the meaningful verification evidence is often lint plus explicit skip reasoning, not synthetic test execution. Writing those skip reasons clearly kept the assignment honest and reviewable.

### Review Cycle Analysis

- `code-valid` found the highest-signal correctness gaps: missing scope clarification, missing artifact-only labeling, mixed invalid-input behavior, and unchecked success criteria.
- `code-fit` focused on contract precision, especially status/exit semantics that would matter to future CLI implementation.
- `code-shine` contributed the final polish layer by aligning verifier evidence ordering and making fixture-path wording explicit.
- Across the three cycles, every verified finding led to concrete task-artifact changes; there was little false-positive churn aside from the preset-role configuration issue and one invalid retro-path claim in the first cycle.

## Action Items

- Remove or correct the undefined `review-geminie` role in the configured review preset so shine-cycle reviews stop failing one configured model before synthesis.
- Consider a lighter-weight assignment tail for docs-only batches that can collapse predictable no-op steps like package release, package docs update, and demo recording.
- Add clearer operator-facing progress telemetry for long `review-pr` subtrees so the drive loop does not look stalled while status remains healthy.
- Document the parent-task auto-archive side effect more prominently in task-update guidance so batch drivers expect the later archive steps to be metadata no-ops.
