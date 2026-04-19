# Goal 8 — Create PR Worktree Lifecycle Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Prerequisite capture exists** — `gh-auth-status.stdout`, `.stderr`, and `.exit` are present.
2. **Create/list capture sets exist** — `create-pr.*`, `list-after-create.*`, and `fs-check.txt` are present.
3. **Create command behavior is explicit** — create-pr.exit is either:
   - 0 with evidence that a PR worktree identifier/path was emitted, or
   - non-zero with concrete upstream/auth error evidence captured in stderr/stdout.
4. **Graceful prerequisite failure is coherent** — if create-pr exits non-zero because `gh` is missing/unauthenticated or PR data cannot be fetched, list-after-create and fs-check must show no partial PR worktree remains; switch/remove/list-after-remove artifacts are not required in this branch.
5. **Switch/remove identifier matches create output** — if create succeeds, switch/remove/list-after-remove capture sets must exist, switch/remove must use the identifier emitted by create output, and outcomes must be consistent.
6. **Final cleanup is consistent** — when create+remove succeed, list-after-remove excludes the PR worktree and fs-check confirms removed path no longer exists.

## Verdict

- **PASS**: Lifecycle behavior is coherent and fully evidenced from public command output and final state artifacts, including the valid graceful-prerequisite-failure branch.
- **FAIL**: Required branch artifacts are missing, command outcomes are inconsistent, or final state checks do not match command claims.

Report: `PASS` or `FAIL` with evidence (exit codes and key output lines).
