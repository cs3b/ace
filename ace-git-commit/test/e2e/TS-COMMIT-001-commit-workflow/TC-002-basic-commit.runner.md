# Goal 2 — Basic Commit

## Goal

Make a change to existing files, then use ace-git-commit with an explicit message (-m) to create a commit. Verify the commit was created with the correct message and includes the changed files.

## Workspace

Save all output to `results/tc/02/`. Capture:
- The command's stdout, stderr, and exit code
- `git log --oneline -1` output showing the commit
- `git show --stat HEAD` output showing committed files

## Constraints

- Modify at least one tracked file (e.g., append content to app.rb or helper.rb).
- Using what you learned from Goal 1, invoke ace-git-commit with -m flag.
- All artifacts must come from real tool execution, not fabricated.
