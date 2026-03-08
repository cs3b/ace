---
id: 8q7hkv
title: ace-compressor-vq4-agent-mode
type: standard
tags: [ace-compressor, agent-mode, assignment]
created_at: "2026-03-08 11:43:12"
status: active
task_ref: 8q6.t.vq4
---

# ace-compressor-vq4-agent-mode

## What Went Well

- **Subtask decomposition worked cleanly**: The 3-subtask split (spike → output contract → validation/fallback) created a natural progression where each subtask built on the previous one's foundation. Version bumps at each stage (0.11.0 → 0.12.0 → 0.13.0) kept releases atomic.
- **Fork-run reliability**: Once stall issues were resolved, all 3 subtask fork-runs completed successfully on first attempt. The codex provider handled implementation phases well within timeout limits.
- **Test coverage scaled incrementally**: Tests grew from 81 → 86 → 87 across subtasks, with assertions growing from 388 → 412 → 444. Each subtask added targeted coverage without regression.
- **Valid review cycle found no actionable issues**: The code-valid review preset found 5 findings, all investigated and marked invalid. Clean first-pass quality from fork agents.
- **Full monorepo stayed green**: 7435 tests, 19117 assertions, 0 failures throughout.

## What Could Be Improved

- **Draft task status blocked fork execution twice**: The fork agent refused to implement from a `draft` task spec, stalling on user confirmation. Had to promote tasks to `pending` then `in-progress` and clear persisted `stall_reason` from the phase file manually. This cost two fork-run cycles (~5 min each).
  - **Root cause**: Assignment was created before task specs were promoted from draft. The `as-task-work` skill gates on task status.
  - **Fix**: Either (a) promote all task specs before creating the assignment, or (b) the assignment creation workflow should auto-promote specs when tasks are assigned.
- **Stall reason persistence required manual file edit**: After clearing the blocking condition (promoting task status), the `stall_reason` field in the phase file persisted from the previous fork session. Had to manually edit the YAML to clear it before re-forking.
  - **Fix**: `ace-assign` should provide a `clear-stall` command, or fork-run should ignore stale stall reasons when re-entering a phase.
- **Accidental retry phase created**: Running `ace-assign retry 010.01.04` to clear the stall created a top-level phase `011-work-on-task` instead of resetting the child phase. Had to manually delete the spurious file.
  - **Fix**: `retry` on a child phase should create a sibling child, not a top-level phase.
- **Review-fit provider failure**: The fit review cycle (070) failed due to provider unavailability (Broken pipe on codex:max, empty output on claude:opus). Circuit breaker policy handled it correctly by skipping shine, but no code review beyond valid was completed.
  - **Impact**: Low — valid cycle already passed clean. But fit/shine coverage was lost for this PR.
- **070 subtree shows pending despite children completing**: After fork-run failure with exit 143, the parent phase 070 stayed `Pending` even though 070.02 and 070.03 were Done. The queue advancement required manual `ace-assign start`.

## Key Learnings

- **Task status must be `in-progress` (not just `pending`) before fork agents will implement**: The `as-task-work` skill has a gate that checks task lifecycle status. Promoting to `pending` wasn't sufficient — needed `in-progress`.
- **Fork stall reasons are persistent state**: They survive across fork-run sessions. The driver must clear them before re-forking if the blocking condition has been resolved externally.
- **Circuit breaker for review cycles works well**: When providers fail, skipping subsequent review cycles is the right call. The valid cycle already covers correctness, which is the highest-priority concern.
- **Batch container iteration pattern is reliable**: Sequential fork-run of each child (010.01 → 010.02 → 010.03) with report review between each worked smoothly after the initial stall resolution.

## Action Items

### Start
- Pre-promote task specs to `in-progress` before creating batch assignments, or add auto-promotion to assignment creation
- Add `ace-assign clear-stall <phase>` command to reset stall reasons without manual file editing

### Continue
- Using circuit breaker policy for review cycles on provider failure
- Reviewing all fork subtree reports before advancing (caught issues early in 010.01)
- Committing task status changes before re-forking to ensure clean state

### Stop
- Using `ace-assign retry` to clear stalls — it creates new phases instead of resetting existing ones
