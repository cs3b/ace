---
description: Run the ACE overseer loop in-process — pick, execute, and close backlog tasks one after another until a stop condition fires
argument-hint: "[task-ref]"
source: ace-handbook-integration-pi
last_modified: 2026-09-27
---

Run the ACE overseer loop **in-process**: this pi session is the overseer. Work the task backlog one task at a time from selection to terminal state, then continue with the next task -- no tmux windows, no detached workers, no external orchestrator. The loop lives in this session; every cycle uses the project's ACE CLI tools.

## Arguments

`${1:-}` is an optional task ref for the first cycle. When omitted, select from the backlog.

## Loop cycle

Repeat until a stop condition fires:

1. **Select.** If `${1:-}` is set and not yet consumed, use it for this cycle and clear it afterwards. Otherwise run `ace-task list` and pick the first `pending` task in priority order that is actionable. Never pick a `done` task; skip tasks whose blocker is confirmed by an executed check (see below).
2. **Execute.** Load the canonical `as-task-work` skill (`/skill:as-task-work <ref>`, or read `.pi/skills/as-task-work/SKILL.md`) and follow it end-to-end for the chosen ref: load the task spec and plan, mark the task in-progress, then work the plan step by step -- test after every change, commit each logical step with `ace-git-commit <paths>`, and leave the task in-progress (final delivery owns `done`).
3. **Verify.** Before closing the cycle: `git status --short` is clean for everything your work produced, and the task's plan checklist and success criteria are satisfied -- or blockers are recorded with executed evidence.
4. **Report.** One progress update per cycle: task ref, outcome (completed / blocked / skipped), and the executed command + observed output that proves it.

## Stop conditions

Stop the loop and give a final summary only when one of these holds:

- **Backlog drained.** `ace-task list` shows no actionable `pending` work.
- **Human decision required.** A task's spec is ambiguous or incomplete, or a blocker cannot be verified or cleared without the user. Do not assume and do not silently skip -- report the blocker together with the executed check that surfaced it.
- **Interrupted.** The user interjects. Yield immediately and summarize the state of every cycle run so far.

## Non-negotiable rules

- Do not stop after intermediate progress; do not pause between cycles for confirmation.
- A cycle that ends blocked on an owner dependency (confirmed by a runnable, non-secret executed check) does not stop the loop: record the blocker on the task with `ace-task update`, close stale blockers in the same pass, and continue with the next task. Only unverifiable or human-only blockers stop the loop.
- Status truth: recorded blockers are claims, not state. Confirm or refute each blocker you rely on with an executed check in this session.
- Never modify task frontmatter directly -- use `ace-task update <ref> --set key=value`.
- Never reset or discard unrelated changes; commit path-scoped with `ace-git-commit <paths>`.
- Temp files go to `/tmp/` or `.ace-local/<subfolder>/`, never the project root.
