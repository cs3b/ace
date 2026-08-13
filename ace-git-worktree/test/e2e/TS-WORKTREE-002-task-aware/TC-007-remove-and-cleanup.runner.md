# Goal 7 — Remove and Cleanup

## Goal

Remove task 8pp.t.r8x worktree by task ID. Then remove task 8pp.t.q7w worktree with the --delete-branch flag (which also deletes the associated branch). Capture clean-state evidence: main worktree intact, both task worktrees gone, branches deleted where specified. Also test the current-branch fallback behavior if applicable.

## Workspace

Save all output to `results/tc/07/`. Capture:
- `results/tc/07/remove-888.stdout`, `.stderr`, `.exit` — remove task 8pp.t.r8x worktree by task ID
- `results/tc/07/remove-999.stdout`, `.stderr`, `.exit` — remove task 8pp.t.q7w worktree with --delete-branch
- `results/tc/07/cleanup-report.stdout`, `.stderr`, `.exit` — cleanup report
- `results/tc/07/cleanup-apply.stdout`, `.stderr`, `.exit` — cleanup apply
- `results/tc/07/list-after.stdout`, `.stderr`, `.exit` — list worktrees after all removals
- `results/tc/07/branch-check.stdout` — git branch listing to verify branch deletion
- `results/tc/07/fs-check.txt` — filesystem check confirming worktree directories are gone

## Constraints

- Use explicit public commands:
  1. `ace-git-worktree remove --task 8pp.t.r8x`
  2. `ace-git-worktree remove --task 8pp.t.q7w --delete-branch`
  3. `ace-git-worktree cleanup --target main --offline` (capture digest)
  4. `ace-git-worktree cleanup --target main --apply --approved-digest <digest> --require-only-target`
  5. `ace-git-worktree list`
- For task 8pp.t.r8x: remove by task ID without deleting the branch.
- For task 8pp.t.q7w: remove by task ID with --delete-branch to also delete the associated branch.
- After removal, verify clean state via list, git branch, and filesystem checks.
- Test the new cleanup report and apply flow to ensure remaining stale/merged state is handled correctly.
- Capture `list-after.*` last, after the branch and filesystem checks, so it is
  the final post-cleanup snapshot for the scenario.
- All artifacts must come from real tool execution, not fabricated.
