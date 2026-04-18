# Goal 8 — Create PR Worktree Lifecycle Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **All capture sets exist** — results/tc/08/ contains stdout/exit for create-pr, list-after-create, switch-pr, remove-pr, and list-after-remove.
2. **Create command behavior is explicit** — create-pr.exit is either:
   - 0 with evidence that a PR worktree identifier/path was emitted, or
   - non-zero with concrete upstream/auth error evidence captured in stderr/stdout.
3. **Switch/remove identifier matches create output** — if create succeeds, switch/remove must use the identifier emitted by create output and produce consistent outcomes.
4. **Final cleanup is consistent** — when create+remove succeed, list-after-remove excludes the PR worktree and fs-check confirms removed path no longer exists.

## Verdict

- **PASS**: Lifecycle behavior is coherent and fully evidenced from public command output and final state artifacts.
- **FAIL**: Artifacts are missing, command outcomes are inconsistent, or final state checks do not match command claims.

Report: `PASS` or `FAIL` with evidence (exit codes and key output lines).
