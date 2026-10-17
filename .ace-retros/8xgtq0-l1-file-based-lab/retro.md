# Batch retrospective — Lab ACE L1 (8xg.t.sbz.0.0/.0.1/.0.2)

Batch: single worktree (`l1-file-based-lab`), single assignment `8xgtq0`, single
draft PR #379. Scope confirmed by the Captain: full L1 removal with the private
`_overseer` store at `.ace-local/overseer/tasks`.

## What went well

- Three parallel read-only audits (old-lab code surface, state ownership, active
  docs) produced a concrete removal boundary before any edit; two Captain
  decisions closed the only blocking ambiguities.
- One assignment drove all three subtasks through onboard/task-load/plan/work/
  review/verify/release/retro, with a single worktree and PR as requested.
- The old protected model was removed rather than shimmed: ~31k lines removed
  across the branch (protected receiver/listener/worker/client stack, generic
  service admission/journal, protected overseer modes, delivery/queue presets,
  protected-only tests and docs), while needed operations and transports stayed.
- The independent reviewer found no P0; the two P1 documentation/consistency
  findings and selected P2 items were fixed and re-verified.
- Task-local state ownership is now explicit and documented; the private store
  is untracked and isolated by construction.

## What could improve

- Plan generation via `ace-task plan` stalled past the three-minute guard; the
  Lead used decision-complete plan artifacts instead. Cache the fallback earlier
  and record the stall in the assignment instructions.
- The full suite's socket-heavy `ace-assign` coverage cannot complete in this
  host/load; the same files also exceed timeouts on unmodified main. A
  deterministic, timeout-bounded replacement is needed.
- README ownership was initially assigned to two workers; one owner per file
  family should be declared at dispatch time.
- A generated `.pi/` provider projection appeared during `ace-handbook sync` and
  had to be removed; generated provider trees should be ignored or explicitly
  scoped.
- Review fixes landed after the release commit, so the release commit was not
  the final code state; keep the release step last or re-bump after review fixes.

## Action items

- L3/L6: remove or re-home the residual protected authority implementation in
  ace-assign; add deterministic coverage for the ordinary path.
- Add a CI/runtime guard for socket-heavy tests (bounded timeouts) so host load
  cannot mask regressions.
- Add a docs lint gate for old owner IDs, `.ace-task` paths and stale
  workflow/skill references in active docs.
- Archive the L1 child tasks after the PR merges and the family closes, updating
  the program links accordingly.
