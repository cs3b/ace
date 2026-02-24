# Goal 5 — Prune Workflow Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **All capture sets exist** — results/tc/05/ contains assignment completion evidence, dry-run, prune, and post-prune captures.
2. **Prune ran from sandbox root** — `pwd-before-dry-run.txt` and `pwd-before-prune.txt` match `sandbox-root-path.txt` and do not point to `task.001`.
3. **Correct prune commands used** — command files show only normal prune flow (`ace-overseer prune --dry-run`, `ace-overseer prune --yes`) with no assignment-prune flags, no `--force`, and no positional targets.
4. **Assignment completion proven** — status-before shows task 001 assignment not completed, `ace-assign report` succeeds, and status-after shows assignment state `completed`.
5. **Prune final state (primary oracle)** — after prune --yes, `worktree-list-after-prune` excludes task.001 worktree and still includes task.002 worktree.
6. **Clean state** — follow-up dry-run shows no safe candidates remaining.

## Verdict

- **PASS**: Prune ran in correct mode/context and final system state matches expectations (task.001 removed, task.002 preserved).
- **FAIL**: Wrong prune mode/context (including forbidden flags/targets), assignment completion missing, final worktree state incorrect, or captures missing.

Report: `PASS` or `FAIL` with evidence.
