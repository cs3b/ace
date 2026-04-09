# Goal 5 — Prune Workflow Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
- Confirm sandbox/project state impact first.
- Confirm explicit artifacts under `results/tc/{NN}/`.
- Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

Checks:
1. **All capture sets exist** — `results/tc/05/` contains assignment-completion evidence, dry-run, prune, and post-prune captures.
2. **Prune ran from sandbox root** — `pwd-before-dry-run.txt` and `pwd-before-prune.txt` match `sandbox-root-path.txt` and do not point to `task-q7w`.
3. **Correct prune commands used** — command files show only normal prune flow (`ace-overseer prune --dry-run`, `ace-overseer prune --yes`) with no assignment-prune flags, no `--force`, and no positional targets.
4. **Applicable safety oracle** — either:
   - assignment completion succeeded and post-prune state removes `q7w` while preserving `r8x`; or
   - assignment completion was explicitly unavailable or blocked, and `task-q7w-assign-status-before.*`, `task-q7w-assign-report.*`, `prune.stdout`, or `dry-run.stdout` explicitly document that `q7w` is not safe to prune.
5. **Final state matches prune output** — `worktree-list-after-prune.stdout` must match the actual prune decision:
   - if prune reports `No worktrees safe to prune` or explicit safety rejection for `q7w`, both `q7w` and `r8x` may remain
   - if prune reports `q7w` pruned, `q7w` must be absent and `r8x` must remain
6. **Clean state** — follow-up dry-run is consistent with the previous prune outcome.

## Verdict

- **PASS**: Prune ran in correct mode/context and final system state matches the applicable completion/safety oracle.
- **FAIL**: Wrong prune mode/context, missing safety/completion evidence, final worktree state contradicts captured prune outcome, or captures missing.

Report: `PASS` or `FAIL` with evidence.
