# Goal 5 — Prune Workflow Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
- Confirm sandbox/project state impact first.
- Use runner observations to identify the q7w worktree path when needed.
- Confirm explicit artifacts under `results/tc/{NN}/`.
- Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

Checks:
1. **All required capture sets exist** — results/tc/05/ contains assignment completion evidence, dry-run, prune, and post-prune captures. `task-q7w-assign-status-before.*` is optional supporting evidence only.
2. **Correct prune flow used** — the captured prune output shows only normal prune flow (`ace-overseer prune --dry-run`, `ace-overseer prune --yes`) with no assignment-prune flags, no `--force`, and no positional targets.
3. **Assignment completion or safety rejection proven** — either:
   - `ace-assign finish --message` succeeds and status-after shows assignment state `completed`; or
   - assignment completion is blocked with explicit safety message (for example no active assignment) and prune output documents safety rejection.
4. **Prune final state (primary oracle)** — one of:
   - if assignment completion succeeded, after prune --yes, `worktree-list-after-prune` excludes task q7w and still includes task r8x; or
   - if assignment completion was explicitly blocked, prune behavior follows task status:
     - when task q7w is still active/in-progress, q7w is preserved with safety rejection evidence; or
     - when task q7w is marked done, q7w may be pruned while r8x remains.
5. **Clean state** — follow-up dry-run shows no safe candidates remaining.

## Verdict

- **PASS**: Prune ran in correct mode/context and final system state matches the applicable oracle (removal after completion, or preservation with explicit safety rejection).
- **FAIL**: Wrong prune mode (including forbidden flags/targets), missing safety/completion evidence, final worktree state contradicts applicable oracle, or captures missing.

Report: `PASS` or `FAIL` with evidence.
