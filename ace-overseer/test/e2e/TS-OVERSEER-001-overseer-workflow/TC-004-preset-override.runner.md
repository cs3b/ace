# Goal 4 -- Preset Override

## Goal

Use `ace-overseer work-on --task 8pp.t.r8x --preset custom-e2e-preset` to create a worktree for a different task with a custom preset. Verify the worktree is created and the assignment reflects the specified preset through public outputs.

## Workspace

Save all output to `results/tc/04/`. Capture:

- The command's stdout, stderr, and exit code
- `ace-git-worktree list` output after the command
- `ace-overseer status --format table` output
- `ace-overseer status --format json` output
- Supporting evidence that ties task 8pp.t.r8x to the created worktree path and custom preset assignment details

## Constraints

- The sandbox has task 8pp.t.r8x and a custom-e2e-preset preset.
- Verify using stable public outputs (`worktree list` and `ace-overseer status`), not hidden/internal files.
- All artifacts must come from real tool execution, not fabricated.
- Mention the created worktree path in final runner observations.
