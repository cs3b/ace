# Goal 5 — Remove Worktree Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Remove artifacts exist** — results/tc/05/ contains stdout/exit for remove and list-after.
2. **Remove succeeds** — remove.exit is 0 for the final removal attempt captured for this goal.
3. **Worktree gone from list** — list-after.stdout no longer includes the removed worktree.
4. **Directory deleted** — fs-check.txt confirms the worktree directory no longer exists on disk. An explicit missing-path result such as `MISSING` is valid evidence.

## Verdict

- **PASS**: Remove exits 0, worktree disappears from list, directory deleted from filesystem.
- **FAIL**: Remove fails, worktree still listed, or directory still present.

Report: `PASS` or `FAIL` with evidence (exit code, list output, filesystem check).
