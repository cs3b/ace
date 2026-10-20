---
description: Resume the commissioned overseer process after a report wake or session restart — same process, same assignments, no self-seeking
argument-hint: "[report-ref]"
source: ace-handbook-integration-pi
last_modified: 2026-10-19
---

Resume the **already commissioned** overseer process in this pi session. This prompt runs on two triggers only: a report/notification message woke the session, or the session restarted. Either way the job is the same — continue the existing commissioned process and its assignments. This session is the one overseer execution: a message arriving while you are already working is a follow-up for THIS run, processed in this turn. Never start a second overseer, window, loop, or agent for the same commission.

## Arguments

`${1:-}` is an optional report/event reference from the waking message. When omitted, discover new reports in step 2.

## Resume cycle

1. **Read truth, not memory.** Reconstruct the current state from the files that own it — never from what the previous turn believed:
   - Private overseer tasks: `ace-task --in _overseer list`, then `ace-task --in _overseer show <ref>` for every `in-progress` task. These define the commissioned process.
   - Assignments: the `ace-assign` plans under `.ace-local/assign/` for those tasks. Steps are read from the assignment; they are not copied anywhere else.
   - Project truth: `ace-task list`, `ace-overseer status`, `ace-git-worktree list`, and `git status --short` in each involved worktree.
2. **Process reports.** Run `ace-overseer process-reports` so incoming ace-hitl reports are interpreted against the managing task and the queue continues. Delivery repetition is not work repetition: an already-processed report (same event id) must not trigger the work again — `process-reports` dedups by event state; trust its output, not the count of wake messages.
3. **Continue the commissioned work.** Run `ace-overseer work-on` to execute the next unblocked step(s) of the commissioned process, and `ace-overseer handoff` when a role finishes and the worktree passes to the next one. Record durable progress in the task folder with `ace-task update` (never edit frontmatter directly).

## Stop conditions

Stop this cycle and give a summary when one of these holds:

- **Commission terminal.** The managing `_overseer` task is `done` — close out with a final report via `ace-hitl`.
- **Blocked on a decision or an owner.** A blocker cannot be verified or cleared without a human or another owner. Record it with `ace-task update`, send the question via `ace-hitl`, and wait. Do not fill the wait with other work.
- **Interrupted.** The user interjects. Yield immediately and summarize the state.

## Non-negotiable rules

- **No self-seeking.** Continue only the commissioned process, its assignments, and unblocked subtasks. When there is no new commissioned work, record that state and wait — do not pick project tasks, backlog items, or "useful" work on your own initiative.
- **Single execution.** Repeated notifications (timer re-fire, redelivered report, duplicate wake) are transport noise for the same commission: verify against report/task state, then continue once. They never justify a second execution.
- **One active worker per worktree.** Before handing off or starting a step, confirm with `ace-git-worktree list` / `ace-overseer status` that the previous role finished; sequential roles share one worktree.
- An unreadable source (missing `_overseer` folder, unreadable assignment, dead runtime) is an error to report, not an empty-and-ready state, and never a reason to start replacement work on the same worktree.
- Never reset or discard unrelated changes; commit path-scoped with `ace-git-commit <paths>`.
- Temp files go to `/tmp/` or `.ace-local/<subfolder>/`, never the project root.
