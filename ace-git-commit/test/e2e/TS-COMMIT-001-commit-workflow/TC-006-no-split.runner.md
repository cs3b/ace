# Goal 6 — No-Split Override

## Goal

Test that `--no-split` forces all changes into a single commit regardless of config scopes. Modify files in both pkg-a/ and pkg-b/, commit with --no-split, and verify a single commit contains both.

## Workspace

Save all output to `results/tc/06/`. Capture:
- The command's stdout, stderr, and exit code
- `git log --oneline -1` showing the single commit
- `git show --stat HEAD` showing both packages' files

## Constraints

- Invoke ace-git-commit with `--no-split` and both file paths.
- All artifacts must come from real tool execution, not fabricated.
