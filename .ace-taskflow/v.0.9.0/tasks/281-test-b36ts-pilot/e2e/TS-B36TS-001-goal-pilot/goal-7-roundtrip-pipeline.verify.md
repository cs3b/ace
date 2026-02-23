# Goal 7 — Roundtrip Pipeline Verification

## Injected Context

The verifier receives the `goal/` directory tree and access to the sandbox path.

## Expectations

1. **File exists** — At least one file exists in `goal/7/`.
2. **Three values present** — The file contains all three components: an original date, an encoded token, and a decoded result.
3. **Valid token** — The encoded token consists of lowercase alphanumeric characters only (base36 charset: `[0-9a-z]`).
4. **Roundtrip match** — The decoded result contains the original date (the roundtrip preserved the input).
5. **No trailing whitespace corruption** — The encoded token has no trailing whitespace or newline characters that would indicate pipe corruption.

## Verdict

- **PASS**: File exists with all three values. Token is valid base36. Decoded result matches the original date. No whitespace corruption evident.
- **FAIL**: File missing, fewer than three values, token invalid, roundtrip mismatch, or evidence of whitespace corruption.

Report: `PASS` or `FAIL` with evidence (the three values found, or the absence/violation).
