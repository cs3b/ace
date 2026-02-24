# Goal 5 — Prune Workflow Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **All capture sets exist** — results/tc/05/ contains assignment completion evidence, dry-run, prune, and post-prune captures.
2. **Assignment completion proven** — status-before shows task 001 assignment not completed, `ace-assign report` succeeds, and status-after shows assignment state `completed`.
3. **Dry-run: no changes** — Dry-run lists task 001 as safe candidate but makes no actual changes.
4. **Prune: only task 001 removed** — After prune --yes, task 001 worktree is removed.
5. **Task 002 preserved** — Task 002 worktree still exists after prune.
6. **Clean state** — Follow-up dry-run shows no safe candidates remaining.

## Verdict

- **PASS**: Assignment completion is evidenced, dry-run is non-destructive, prune removes only safe worktree, unsafe worktree preserved.
- **FAIL**: Assignment completion missing, dry-run makes changes, wrong worktree removed/preserved, or captures missing.

Report: `PASS` or `FAIL` with evidence.
