# Goal 3 — File Pattern Matching Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **Artifacts exist** — results/tc/03/ contains stdout capture and/or analysis file.
2. **Included files present** — Output contains content from README.md ("Test Application"), src/main.js ("Hello World"), and src/utils.js ("helper()").
3. **Excluded files absent** — Output does not contain test file content (e.g., "describe('Main'" from test/main.test.js) unless included by another pattern.

## Verdict

- **PASS**: Matching files included in output, non-matching files excluded.
- **FAIL**: Expected files missing or excluded files incorrectly included.

Report: `PASS` or `FAIL` with evidence (content presence/absence in output).
