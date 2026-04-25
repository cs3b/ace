---
id: 8rnzki
title: 8rn-t-z5k-0-watch-recovery-callback-contract
type: standard
tags: []
created_at: "2026-04-24 23:42:47"
status: active
---

# 8rn-t-z5k-0-watch-recovery-callback-contract

## What Went Well

- The existing owner-layer contract was already strong enough to ground the task artifact updates without touching runtime code. `fork-run`, the fork session launcher, the drive workflow, and current fast tests all lined up on the same status-first recovery model.
- The subtask stayed narrow. The final change set only touched the task spec and task-local `ux/usage.md`, which kept the release step correctly in no-op territory.
- The fallback quality gate was straightforward. Native `/review` commands were not available in this execution path, but `ace-lint` on the modified task artifacts gave a deterministic pre-commit check with no findings.

## Key Learnings

- Callback compatibility needs explicit ownership language. Without saying that callback text is only a wake-up hint, it is easy for later implementers to blur the boundary between operator signals and assignment truth.
- For this watcher family, scoped recovery rules are just as important as completion rules. The task artifacts needed to say plainly that a resumed watcher or drive process recovers from assignment state and never widens a scoped target back to the parent.
- Task-local `ux/usage.md` is carrying real acceptance weight in this family. Adding a dedicated interactive callback scenario made the artifact set more complete than leaving callback behavior implied inside prose.

## What Could Be Improved

- The review step currently depends on environment detection and fallback behavior. If native slash-command review is expected to be common in forked tmux sessions, the repo could benefit from a more explicit executable pre-commit review path for non-chat contexts.
- The verify step language allows a docs-only skip, but it still reads like a code-focused test gate. A clearer artifact-only verification variant would reduce ambiguity for documentation/design subtasks.

## Action Items

- Keep future watcher implementation work anchored to `ace-assign status` as the only completion/failure authority.
- Preserve the current `ACE_ASSIGN_CALLBACK_PANE` single-sentence tmux callback behavior unless a later task intentionally evolves it.
- If a future task wants emitted `ACE_ASSIGN_EVENT` output, draft it as a separate follow-up instead of extending this v1 contract implicitly.
