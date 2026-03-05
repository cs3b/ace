# Goal 4 — Preset Override

## Goal

Use `ace-overseer work-on --task 8pp.t.r8x --preset custom-e2e-preset` to create a worktree for a different task with a custom preset. Verify the worktree is created and the assignment uses the specified preset.

## Workspace

Save all output to `results/tc/04/`. Capture:
- The command's stdout, stderr, and exit code
- Worktree verification for task 8pp.t.r8x
- Assignment details showing the custom preset was used

## Constraints

- The sandbox has task 8pp.t.r8x and a custom-e2e-preset preset.
- Using what you learned from Goal 1, invoke with --preset flag.
- All artifacts must come from real tool execution, not fabricated.
