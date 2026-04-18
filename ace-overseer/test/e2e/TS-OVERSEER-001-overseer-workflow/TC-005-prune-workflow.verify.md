# Goal 5 -- Prune Workflow Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):

- Confirm sandbox/project state impact first.
- Use runner observations to identify the q7w worktree path when needed.
- Confirm explicit artifacts under `results/tc/{NN}/`.
- Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

Checks:
1. **Required captures exist** -- results/tc/05/ contains `task-done.*`, `dry-run.*`, `prune.*`, `worktree-list-after-prune.*`, and `dry-run-final.*`.
2. **Correct prune flow used** -- the captured artifacts match the normal public prune flow only: `dry-run.*`, `prune.*`, and `dry-run-final.*` are present, and there is no evidence of forbidden flags/targets or assignment/force prune modes.
3. **Safety oracle** -- if q7w still has an incomplete assignment, prune reports 0 safe candidates / 0 pruned worktrees and `worktree-list-after-prune` still includes q7w; task r8x also remains present.
4. **Clean follow-up state** -- final dry-run shows no remaining safe prune candidates.

## Verdict

- **PASS**: Normal prune flow executed and final system state matches the expected safety oracle, including retaining unsafe worktrees.
- **FAIL**: Wrong prune mode, missing required captures, or final worktree state contradicts expected behavior.

Report: `PASS` or `FAIL` with evidence.
