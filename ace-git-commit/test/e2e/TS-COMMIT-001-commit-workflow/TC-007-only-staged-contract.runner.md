# Goal 7 — Only-Staged Contract

## Goal

Test that `--only-staged` commits only files already in the git index and
leaves unstaged changes untouched in the working tree.

## Workspace

Save all output to `results/tc/07/`. Capture:
- The command's stdout, stderr, and exit code
- `git status --short` before and after the command
- `git show --stat HEAD` for the new commit
- Evidence of one staged file and one unstaged file before invoking
  `ace-git-commit --only-staged`

## Constraints

- Modify at least two tracked files.
- Stage only one file with `git add`.
- Leave at least one modified file unstaged.
- Invoke `ace-git-commit --only-staged -m "<message>"`.
- Verify the committed diff includes only staged file(s) and unstaged
  modifications remain after the commit.
- All artifacts must come from real tool execution, not fabricated.
