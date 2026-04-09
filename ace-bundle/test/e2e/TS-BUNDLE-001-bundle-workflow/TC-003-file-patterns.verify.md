# Goal 3 — File Pattern Matching Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Artifacts exist** — results/tc/03/ contains stdout capture and/or analysis file.
2. **Included files present** — Output includes `README.md`, `src/main.js`, and `src/utils.js`. README proof may be semantic or structured formatter output (for example the README path plus normalized content about the test application), not necessarily the literal source heading text.
3. **Excluded files absent** — Output does not contain test file content (e.g., "describe('Main'" from test/main.test.js) unless included by another pattern.

## Verdict

- **PASS**: Matching files included in output, non-matching files excluded.
- **FAIL**: Expected files missing or excluded files incorrectly included.

Report: `PASS` or `FAIL` with evidence (content presence/absence in output).
