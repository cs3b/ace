# Goal 3 — Dry Run and Path Handling

## Goal

Test two behaviors: (1) dry-run mode (-n) shows planned changes without committing, and (2) specifying a single file path only commits that file, leaving other changes uncommitted.

## Workspace

Save all output to `results/tc/03/`. Capture:
- Dry run: stdout, stderr, exit code, and proof HEAD was unchanged
- Path handling: stdout, stderr, exit code, git show --stat, and proof other files remain untracked/unstaged

## Constraints

- For dry run: stage a change, record HEAD, run with -n, verify HEAD unchanged and changes still staged.
- For path handling: modify two files, commit only one by specifying its path, verify the other remains uncommitted.
- Use explicit flags in your commands (`-n` for dry-run and path arguments for path handling).
- All artifacts must come from real tool execution, not fabricated.
