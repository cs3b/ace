# Goal 2 — Work-On Happy Path

## Goal

Use `ace-overseer work-on` with task 001 to create a worktree, open a tmux window, and initialize an assignment using the default preset. Verify all three resources are created.

## Workspace

Save all output to `results/tc/02/`. Capture:
- The command's stdout, stderr, and exit code
- Worktree verification (ace-git-worktree list showing task 001)
- Tmux verification (tmux list showing window for task)
- Assignment verification (ace-assign status showing active assignment)

## Constraints

- The sandbox has task 001 in .ace-taskflow/ and default preset in .ace/assign/presets/.
- Using what you learned from Goal 1, invoke ace-overseer work-on.
- All artifacts must come from real tool execution, not fabricated.
