# Goal 7 — Remove and Cleanup Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **All removal artifacts exist** — results/tc/07/ contains captures for remove-888, remove-999, cleanup-report, cleanup-apply, list-after, branch-check, and fs-check.
2. **Both removals succeed** — remove-888.exit and remove-999.exit are both 0.
3. **Cleanup report succeeds** — cleanup-report.exit is 0 and output contains a Plan Digest.
4. **Cleanup apply succeeds** — cleanup-apply.exit is 0 and output confirms strict rescan digest matches.
5. **Clean worktree list** — list-after.stdout shows only the main worktree (no task worktrees remain).
6. **Branch deletion for 8pp.t.q7w** — branch-check.stdout confirms the task 8pp.t.q7w branch was deleted (not present in branch list).
7. **Directories gone** — fs-check.txt confirms both task worktree directories no longer exist on the filesystem.

## Verdict

- **PASS**: Both task worktrees removed, cleanup executed successfully without drift failure, main intact, branch deleted for task 8pp.t.q7w, directories cleaned up.
- **FAIL**: Removal or cleanup fails, task worktrees still listed, branch not deleted, or directories still present.

Report: `PASS` or `FAIL` with evidence (exit codes, list output, branch list, filesystem check, cleanup digest).
