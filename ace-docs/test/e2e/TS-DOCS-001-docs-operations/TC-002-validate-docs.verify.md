# Goal 2 — Validate Docs Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/02/validate.stdout`, `.stderr`, and `.exit` exist.
2. `results/tc/02/validate.exit` contains a numeric code.
3. `results/tc/02/validate.stdout` includes validation-result indicators (for example `valid`, `invalid`, or summary text).
4. If setup fallback was required, `results/tc/02/setup.*` is present.

## Verdict

- **PASS**: Validation captures are complete and demonstrate concrete validation behavior.
- **FAIL**: Missing artifacts, malformed exit capture, or no validation evidence in output.
