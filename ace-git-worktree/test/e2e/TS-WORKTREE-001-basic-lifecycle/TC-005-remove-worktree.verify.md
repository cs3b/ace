# Goal 5 — Remove Worktree Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **Remove artifacts exist** — results/tc/05/ contains stdout/exit for remove and list-after.
2. **Remove succeeds** — remove.exit is 0.
3. **Worktree gone from list** — list-after.stdout no longer includes the removed worktree.
4. **Directory deleted** — fs-check.txt confirms the worktree directory no longer exists on disk.

## Verdict

- **PASS**: Remove exits 0, worktree disappears from list, directory deleted from filesystem.
- **FAIL**: Remove fails, worktree still listed, or directory still present.

Report: `PASS` or `FAIL` with evidence (exit code, list output, filesystem check).
