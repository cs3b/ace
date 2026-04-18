# Goal 2 — Validate Docs Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. Seeded docs corpus is still present (`docs/guide.md`, `docs/reference.md`) before evaluating command output.
2. `results/tc/02/validate.stdout`, `.stderr`, and `.exit` exist.
3. `results/tc/02/validate.exit` contains a numeric code.
4. Validation output includes concrete outcome evidence (`valid`, `invalid`, `issues`, or equivalent summary categories), without requiring exact phrasing.

## Verdict

- **PASS**: Seeded docs exist and validation captures demonstrate concrete validation outcome behavior.
- **FAIL**: Missing seeded docs/artifacts, malformed exit capture, or no validation outcome evidence.
