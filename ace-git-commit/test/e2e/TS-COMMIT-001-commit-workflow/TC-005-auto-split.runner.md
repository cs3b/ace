# Goal 5 — Auto-Split

## Goal

Test that `ace-git-commit` automatically creates separate commits when files
span multiple configuration scopes. Set up the split contract explicitly with
public config files, modify files in both `pkg-a/` and `pkg-b/`, commit both
paths in one invocation, and verify two separate commits are created.

## Workspace

Save all output to `results/tc/05/`. Capture:
- The command's stdout, stderr, and exit code
- Setup evidence showing explicit scope config creation
- `git log --oneline -3` showing the separate commits
- `git show --stat HEAD` and `git show --stat HEAD~1` showing files in each commit

## Constraints

- Create explicit package configs in the sandbox before running the command:
  - `pkg-a/.ace/git/commit.yml`
  - `pkg-b/.ace/git/commit.yml`
- Keep setup on public file/config surfaces; do not rely on hidden fixture-only
  assumptions.
- Modify a file in each package, then commit both paths at once.
- Invoke `ace-git-commit` with both package paths in one command.
- All artifacts must come from real tool execution, not fabricated.
