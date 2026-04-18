# Goal 3 — Dry Run and Path Handling

## Goal

Test two behaviors: (1) dry-run mode (-n) shows planned changes without committing, and (2) specifying a single file path only commits that file, leaving other changes uncommitted.

## Workspace

Save all output to `results/tc/03/`.

Use two explicit capture groups:
- Dry run under `results/tc/03/dry-run/`
- Path handling under `results/tc/03/path-only/`

Capture:
- Dry run:
  - `results/tc/03/dry-run/ace-git-commit.stdout`, `.stderr`, `.exit`
  - `results/tc/03/dry-run/head-before.txt`
  - `results/tc/03/dry-run/head-after.txt`
  - `results/tc/03/dry-run/status-after.txt`
- Path handling:
  - `results/tc/03/path-only/ace-git-commit.stdout`, `.stderr`, `.exit`
  - `results/tc/03/path-only/git-show-stat.stdout`
  - `results/tc/03/path-only/status-after.txt`

## Constraints

- For dry run: stage a change, record HEAD, run with -n, verify HEAD unchanged and changes still staged.
- For path handling: modify two files, commit only one by specifying its path, verify the other remains uncommitted.
- Use explicit flags in your commands (`-n` for dry-run and path arguments for path handling).
- Persist the full dry-run capture group before starting path handling.
- Persist the full path-handling capture group before finishing the goal.
- All artifacts must come from real tool execution, not fabricated.
