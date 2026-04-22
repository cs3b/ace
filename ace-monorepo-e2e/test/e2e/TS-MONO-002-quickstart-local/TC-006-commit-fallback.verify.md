# Goal 6 -- Setup Commit Fallback Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) as fallback.

1. **Primary attempt evidence exists** -- `results/tc/06/goal-commit.exit`, `.stdout`, and `.stderr` files exist.
2. **Fallback command succeeds** -- `results/tc/06/fallback-commit.exit` is numeric and `0`.
3. **Fallback commit message is applied** -- `results/tc/06/head-show.stdout` includes `chore: set up ace tooling`.
4. **Staged-change contract captured** -- `results/tc/06/pre-status.stdout` and `results/tc/06/fallback-pre-status.stdout` are non-empty.
5. **Recent log evidence exists** -- `results/tc/06/log.stdout` includes at least one commit line referencing setup/fallback commit history.
6. **If primary attempt failed, output is actionable** -- when `goal-commit.exit` is non-zero, either `goal-commit.stdout` or `goal-commit.stderr` includes guidance-like content (for example mentions of `-m`, `message`, or fallback wording).

## Verdict

- **PASS**: Fallback path succeeds deterministically and commit/log evidence is present.
- **FAIL**: Missing artifacts, non-zero fallback exit, or missing fallback commit evidence.

Report: `PASS` or `FAIL` with evidence (artifact file names and key snippets).
