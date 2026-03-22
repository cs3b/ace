---
id: 8qljs0
status: done
title: "Shorten Worktree Naming to <prefix>-<task-ref>"
tags: []
created_at: "2026-03-22 13:11:07"
---

# Shorten Worktree Naming to <prefix>-<task-ref>

## What I Hope to Accomplish
Streamline the development environment by shortening worktree directory names. Long directory names like `ace-task.uno` consume significant horizontal space in terminal prompts and IDE tabs. Using a compact `<projectprefix>-<task-ref>` format (e.g., `ace-t.uno`) improves readability while maintaining clear traceability to the underlying task.

## What "Complete" Looks Like
The `ace-git-worktree` tool is updated to default to the shortened naming convention. `ace-overseer` and other related tools seamlessly support this transition, ensuring that task-to-worktree mapping remains robust and that existing worktrees using the old scheme are still recognized.

## Success Criteria
- New worktrees are created using the shortened naming scheme (e.g., `ace-t.uno`).
- `ace-git-worktree` logic correctly handles the `<projectprefix>-<task-ref>` derivation.
- `ace-overseer status` and other commands correctly list and manage worktrees with the new naming scheme.
- Backwards compatibility is maintained for existing worktrees that use the older naming convention.
