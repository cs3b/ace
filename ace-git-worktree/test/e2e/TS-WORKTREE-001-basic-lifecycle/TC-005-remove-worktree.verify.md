# Goal 5 — Remove Worktree Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Remove artifacts exist** — results/tc/05/ contains stdout/exit for remove, list-after, and git-worktree-porcelain-after.
2. **Remove succeeds** — remove.exit is 0.
3. **Git metadata is clean** — git-worktree-porcelain-after.stdout does not include the removed `feature/test-worktree` worktree path.
4. **Directory deleted** — fs-check.txt records the removed worktree path and confirms `exists=no`.

## Verdict

- **PASS**: Remove exits 0, git metadata no longer includes the removed worktree, and fs-check.txt confirms the exact removed path no longer exists.
- **FAIL**: Remove fails, git metadata still includes the removed worktree, or fs-check.txt does not confirm `exists=no` for the removed path.

Report: `PASS` or `FAIL` with evidence (exit code, git metadata output, filesystem check).
