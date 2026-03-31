# Goal 2 — Normal Bundle Install Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Exit code captured** — `results/tc/02/install.exit` exists and contains a numeric value.
2. **Output captured** — `results/tc/02/install.stdout` exists and is non-empty.
3. **Success evidence** — If exit code is `0`, `bundle-list.stdout` should exist and mention at least one `ace-*` gem.
4. **Failure evidence** — If exit code is non-zero, `install.stdout` should contain error details (resolution failure, dependency conflict, etc.).

## Verdict

- **PASS**: Exit code and output are captured; if successful, bundle list confirms gem presence; if failed, error output is substantive.
- **FAIL**: Missing exit code, missing output, or empty captures.

Report: `PASS` or `FAIL` with evidence (exit code value, key output snippets).
