# Goal 5 — Auto-Split

## Goal

Test that ace-git-commit automatically creates separate commits when files span multiple configuration scopes (different packages with different `.ace/git/commit.yml` configs). Modify files in both pkg-a/ and pkg-b/, commit them together, and verify two separate commits are created.

## Workspace

Save all output to `results/tc/05/`. Capture:
- The command's stdout, stderr, and exit code
- `git log --oneline -3` showing the separate commits
- `git show --stat HEAD` and `git show --stat HEAD~1` showing files in each commit

## Constraints

- The sandbox has pkg-a/ and pkg-b/ with separate `.ace/git/commit.yml` configs.
- Modify a file in each package, then commit both paths at once.
- Invoke ace-git-commit with both package paths in one command.
- All artifacts must come from real tool execution, not fabricated.
