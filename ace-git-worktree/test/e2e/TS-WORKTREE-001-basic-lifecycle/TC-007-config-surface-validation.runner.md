# Goal 7 — Config Surface Validation

## Goal

Validate that the public configuration surface is usable from the CLI by running show, validate, and files commands. Capture outputs that prove users can inspect active configuration and confirm whether it is valid.

## Workspace

Save all output to `results/tc/07/`. Capture:
- `results/tc/07/config-show.stdout`, `.stderr`, `.exit` — `ace-git-worktree config --show`
- `results/tc/07/config-validate.stdout`, `.stderr`, `.exit` — `ace-git-worktree config --validate`
- `results/tc/07/config-files.stdout`, `.stderr`, `.exit` — `ace-git-worktree config --files`

## Constraints

- Use explicit public commands:
  1. `ace-git-worktree config --show`
  2. `ace-git-worktree config --validate`
  3. `ace-git-worktree config --files`
- All artifacts must come from real tool execution, not fabricated.
- Do not manually edit configuration files for this goal; validate the default sandbox state as-is.
