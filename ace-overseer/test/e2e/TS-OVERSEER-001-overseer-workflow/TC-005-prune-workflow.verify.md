# Goal 5 — Prune Workflow Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **All capture sets exist** — results/tc/05/ contains dry-run, prune, and post-prune captures.
2. **Dry-run: no changes** — Dry-run lists task 001 as safe candidate but makes no actual changes.
3. **Prune: task 001 removed** — After prune --yes, task 001 worktree is removed.
4. **Prune: task 002 preserved** — Task 002 worktree still exists after prune.
5. **Clean state** — Follow-up dry-run shows no safe candidates remaining.

## Verdict

- **PASS**: Dry-run is non-destructive, prune removes only safe worktree, unsafe worktree preserved.
- **FAIL**: Dry-run makes changes, wrong worktree removed/preserved, or captures missing.

Report: `PASS` or `FAIL` with evidence.
