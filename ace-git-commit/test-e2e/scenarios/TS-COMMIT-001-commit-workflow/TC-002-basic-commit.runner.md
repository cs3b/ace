# Goal 2 — Basic Commit

## Goal

Make a change to existing files, then use ace-git-commit with an explicit message (-m) to create a commit. Verify the commit was created with the correct message and includes the changed files.

## Workspace

Save all output to `results/tc/02/`. Capture:
- The command's stdout, stderr, and exit code
- `git rev-parse HEAD` output showing the created commit SHA
- `git log --oneline -1` output showing the commit
- `git show --stat <captured-sha>` output showing committed files

## Constraints

- Modify at least one tracked file (e.g., append content to app.rb or helper.rb).
- Invoke ace-git-commit with `-m` and an explicit commit message.
- Capture the commit SHA immediately after the commit and use that SHA for any
  subsequent verification artifacts for this goal.
- All artifacts must come from real tool execution, not fabricated.
