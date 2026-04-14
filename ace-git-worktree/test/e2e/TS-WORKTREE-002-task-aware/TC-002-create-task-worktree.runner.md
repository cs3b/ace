# Goal 2 — Create Task Worktree

## Goal

Create a worktree for task 8pp.t.q7w using the task-aware creation mechanism. Capture creation output, verify the branch name includes the task identifier token (`q7w`), and confirm the created worktree path exists on disk with the expected task-aware layout.

## Workspace

Save all output to `results/tc/02/`. Capture:
- `results/tc/02/create-task.stdout`, `.stderr`, `.exit` — create worktree for task 8pp.t.q7w
- `results/tc/02/branch-check.stdout` — git branch or worktree info showing the branch name includes task identifier token `q7w`
- `results/tc/02/fs-check.txt` — filesystem evidence that the created worktree path exists and points at the task-aware directory for `q7w`

## Constraints

- Using what you learned from Goal 1, invoke ace-git-worktree create with task-aware flags for task 8pp.t.q7w.
- The sandbox has taskflow fixtures with task 8pp.t.q7w (8pp.t.q7w-test-feature) already defined.
- All artifacts must come from real tool execution, not fabricated.
- Use the worktree path printed by the create command when producing `fs-check.txt`; this goal should validate creation directly, not repeat the filter checks covered in Goal 3.
