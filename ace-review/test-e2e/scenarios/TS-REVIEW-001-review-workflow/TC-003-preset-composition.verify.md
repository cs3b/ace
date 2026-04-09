# Goal 3 — Preset Composition Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Both capture sets exist** — results/tc/03/ contains stdout/exit for both level_3 and code-pr tests.
2. **Both exit codes zero** — Both dry-runs succeeded.
3. **Dry-run artifacts produced** — Both stdout captures show review session preparation (for example, "Review session prepared" and prompt file paths).
4. **No empty-subject error** — Neither stderr contains "No code to review".

## Verdict

- **PASS**: Both dry-runs succeed and produce prepared review session artifacts without empty-subject errors.
- **FAIL**: Either dry-run fails or expected dry-run artifacts are missing.

Report: `PASS` or `FAIL` with evidence (exit codes, output showing resolution).
