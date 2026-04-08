# Goal 6 — Prune Orphaned Worktree Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **All required artifacts exist** — results/tc/06/ contains orphan-target path, prune captures, list-after, git-worktree-porcelain-after, and fs-state-after.
2. **Prune command succeeded** — prune.exit is 0.
3. **Final git metadata is clean** — git-worktree-porcelain-after shows only expected remaining worktrees and does not contain the orphan target.
4. **Final filesystem is clean** — fs-state-after confirms orphan target path does not exist. An explicit missing-path result such as `MISSING` is valid evidence.
5. **Final list is consistent** — list-after.stdout matches the clean post-prune state (no orphaned worktree entry).

`prune --dry-run` output is diagnostic only and must not override final-state checks.

## Verdict

- **PASS**: Final system state is clean after prune (git metadata + filesystem + list consistency).
- **FAIL**: Prune fails or final system state still contains orphan artifacts/entries.

Report: `PASS` or `FAIL` with evidence, prioritizing final-state artifacts.
