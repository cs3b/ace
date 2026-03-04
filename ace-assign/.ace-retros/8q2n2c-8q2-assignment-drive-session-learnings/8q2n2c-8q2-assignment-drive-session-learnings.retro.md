---
id: 8q2n2c
title: 8q2-assignment-drive-session-learnings
type: standard
tags: [assign, workflow, self-improve]
created_at: "2026-03-03 15:22:37"
status: active
---

# 8q2-assignment-drive-session-learnings

Session learnings from assignment 8q2l5l (plan-first task execution, task 8q2.t.hy4).

## What Went Well

- The assignment/fork-run architecture worked end-to-end for a multi-phase workflow
- Fork crash recovery protocol (commit partial work, inject recovery phases, re-fork) proved effective
- Subtree guard pattern caught quality issues before they propagated

## What Could Be Improved

- **Fork-run targeting for nested batch containers**: The drive workflow said "if FORK: yes, delegate via fork-run" but batch containers (e.g., 010) show `FORK: yes` because they have children, even though they lack `context: fork`. The agent tried to fork the container, failed, then had to discover the correct target through trial-and-error. Wasted ~2 cycles.
- **Queue stalling after batch container auto-completion**: After all fork subtrees completed, the batch container auto-marked as Done but the queue pointer didn't advance. The driver had to manually discover `ace-assign start` was needed — not documented in the drive workflow.
- **Non-existent CLI command in presets**: All mark-task-done presets referenced `ace-task manage-status done` which doesn't exist. The correct command is `ace-task update --set status=done --move-to archive`.

## Key Learnings

- Batch containers and fork-enabled phases are distinct concepts: a container aggregates children but isn't itself a fork target
- Queue advancement is not always automatic — explicit `ace-assign start` may be needed after batch completion
- Preset commands should be validated against actual CLI help output before shipping

## Action Items

- [x] **Fix drive.wf.md**: Add "Nested Batch Containers" subsection clarifying container vs. direct fork targets
- [x] **Fix drive.wf.md**: Add "Queue Advancement After Batch Container Completion" section after subtree guard
- [x] **Fix 5 preset files**: Replace `ace-task manage-status done` with `ace-task update --set status=done --move-to archive`
- [x] **Verify**: All tests pass, no remaining `manage-status` references
