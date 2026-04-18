# Goal 4 — Delete and Rename

## Goal

Test that ace-git-commit correctly handles file deletions and renames. Delete a tracked file and commit it. Then rename a file with `git mv` and commit that alongside a modification.

## Workspace

Save all output to `results/tc/04/`. Capture:
- Delete commit: stdout, stderr, exit code, git show --stat
- Rename+modify commit: stdout, stderr, exit code, git show --stat
- Final state verification:
  - `final-deleted.exit` from `test ! -e to_delete.rb`
  - `final-renamed.exit` from `test -f new_name.rb`
  - `final-keeper.txt` with the full contents of `keeper.rb`

## Constraints

- Use `rm` to delete to_delete.rb, then commit with ace-git-commit.
- After deleting `to_delete.rb`, stage the deletion explicitly before committing (for example `git add -A to_delete.rb`) so the delete-only commit is unambiguous.
- Prefer a path-scoped delete commit for this step (for example `ace-git-commit to_delete.rb`) so unrelated file state cannot interfere with the delete-only assertion.
- Use `git mv` for the rename (old_name.rb → new_name.rb), modify keeper.rb, then commit both.
- Prefer a path-scoped rename commit for this step (for example `ace-git-commit new_name.rb keeper.rb`) so the rename+modify assertion stays focused on the intended files.
- Capture explicit final-state evidence with real shell commands, for example:
  - `test ! -e to_delete.rb`
  - `test -f new_name.rb`
  - `cat keeper.rb`
- Persist those final-state checks as the named artifacts above so the verifier can use them as the primary oracle instead of inferring rename heuristics from `git show --stat`.
- All artifacts must come from real tool execution, not fabricated.
