# Goal 7 -- Work-On Multi-Task Bundle Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):

- Confirm sandbox/project state impact first.
- Confirm explicit artifacts under `results/tc/07/`.
- Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

Checks:
1. **Required captures exist** -- multi-task command and post-state outputs are present.
2. **Command succeeded** -- multi-task work-on exits with code 0.
3. **Primary task represented in public state** -- worktree list and status JSON show one orchestration record for the first resolved task ref recorded in `task-a.ref.txt`.
4. **No duplicate ambiguity** -- public-state evidence does not indicate duplicate entries for the primary task in a single invocation, and the command accepts multiple task refs without malformed output.

## Verdict

- **PASS**: Multi-task invocation succeeds, the primary task is represented in post-run public state, and the invocation does not create duplicate/ambiguous state.
- **FAIL**: Command failure, missing primary-task evidence, or duplicate/ambiguous state.

Report: `PASS` or `FAIL` with evidence.
