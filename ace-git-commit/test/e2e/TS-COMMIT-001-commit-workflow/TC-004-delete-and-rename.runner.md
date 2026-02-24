# Goal 4 — Delete and Rename

## Goal

Test that ace-git-commit correctly handles file deletions and renames. Delete a tracked file and commit it. Then rename a file with `git mv` and commit that alongside a modification.

## Workspace

Save all output to `results/tc/04/`. Capture:
- Delete commit: stdout, stderr, exit code, git show --stat
- Rename+modify commit: stdout, stderr, exit code, git show --stat
- Final state verification (deleted file absent, renamed file present)

## Constraints

- Use `rm` to delete to_delete.rb, then commit with ace-git-commit.
- Use `git mv` for the rename (old_name.rb → new_name.rb), modify keeper.rb, then commit both.
- All artifacts must come from real tool execution, not fabricated.
