# Goal 5 — Remove Worktree Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Remove artifacts exist** — results/tc/05/ contains stdout/exit for remove and list-after.
2. **Remove succeeds** — remove.exit is 0.
3. **Correct worktree removed from list** — list-after.stdout no longer includes `feature/test-worktree`.
4. **Directory deleted** — fs-check.txt records the removed worktree path and confirms `exists=no`.

## Verdict

- **PASS**: Remove exits 0, `feature/test-worktree` is gone from the list output, and fs-check.txt confirms the exact removed path no longer exists.
- **FAIL**: Remove fails, the worktree still appears in list output, or fs-check.txt does not confirm `exists=no` for the removed path.

Report: `PASS` or `FAIL` with evidence (exit code, list output, filesystem check).
