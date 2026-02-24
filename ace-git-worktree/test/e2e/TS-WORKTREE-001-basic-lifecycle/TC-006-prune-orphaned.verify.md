# Goal 6 — Prune Orphaned Worktree Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **All artifacts exist** — results/tc/06/ contains orphan-create evidence, prune-dry captures, prune captures, and list-after.
2. **Orphan created** — orphan-create.txt confirms the worktree directory was manually deleted.
3. **Dry-run detects orphan** — prune-dry.stdout identifies the orphaned worktree entry.
4. **Prune cleans up** — prune.exit is 0 and output indicates the orphan was cleaned.
5. **Clean state after prune** — list-after.stdout shows only the main worktree (all created worktrees are gone).

## Verdict

- **PASS**: Orphan detected by dry-run, cleaned by prune, final list shows only main.
- **FAIL**: Orphan not detected, prune fails, or orphan still appears after prune.

Report: `PASS` or `FAIL` with evidence (prune output, list after prune).
