# Phase 4: Coworker Environment (The Office)

## Goal
To provide the physical and logical container for the Overseer sessions, ensuring isolation from the user's main working directory and from other active sessions.

## Architecture: Git Worktrees
`ace-coworker` leverages `ace-git-worktree` to spawn isolated environments.

1.  **Session Creation**:
    *   Command: `ace-coworker start --task <id>`
    *   Action: Creates a new git worktree at `.ace/coworker/task-<id>`.
    *   Branch: `ace-coworker/task-<id>`.

2.  **The "Office" Dashboard**:
    *   A TUI (Text User Interface) or CLI list that shows active sessions.
    *   Status: `Running`, `Waiting for Approval`, `Error`, `Done`.

3.  **Interaction**:
    *   The user interacts with the **Coworker**, not the Overseer directly.
    *   Commands:
        *   `ace-coworker list`
        *   `ace-coworker logs <id>`
        *   `ace-coworker approve <id>`
        *   `ace-coworker stop <id>`

## File System Structure
```
.ace/
  coworker/
    task-123/        # The Git Worktree (The "Room")
      .ace-overseer/ # Overseer's local state
        state.json   # Current phase/status
        logs/        # Session logs
        context/     # Context files for workers
```
