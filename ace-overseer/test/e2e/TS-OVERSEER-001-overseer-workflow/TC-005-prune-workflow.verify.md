# Goal 5 — Prune Workflow Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
- Confirm sandbox/project state impact first.
- Confirm explicit artifacts under `results/tc/{NN}/`.
- Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

Checks:
1. **All capture sets exist** — results/tc/05/ contains assignment completion evidence, dry-run, prune, and post-prune captures.
2. **Prune ran from sandbox root** — `pwd-before-dry-run.txt` and `pwd-before-prune.txt` match `sandbox-root-path.txt` and do not point to `task-q7w`.
3. **Correct prune commands used** — command files show only normal prune flow (`ace-overseer prune --dry-run`, `ace-overseer prune --yes`) with no assignment-prune flags, no `--force`, and no positional targets.
4. **Assignment completion or safety rejection proven** — either:
   - status-before shows task q7w assignment not completed, `ace-assign finish --message` succeeds, and status-after shows assignment state `completed`; or
   - assignment completion is blocked with explicit safety message (for example no active assignment) and prune output documents safety rejection.
5. **Prune final state (primary oracle)** — one of:
   - if assignment completion succeeded, after prune --yes, `worktree-list-after-prune` excludes task q7w and still includes task r8x; or
   - if assignment completion was explicitly blocked, prune preserves task q7w and task r8x with clear safety rejection evidence.
6. **Clean state** — follow-up dry-run shows no safe candidates remaining.

## Verdict

- **PASS**: Prune ran in correct mode/context and final system state matches the applicable oracle (removal after completion, or preservation with explicit safety rejection).
- **FAIL**: Wrong prune mode/context (including forbidden flags/targets), missing safety/completion evidence, final worktree state contradicts applicable oracle, or captures missing.

Report: `PASS` or `FAIL` with evidence.
