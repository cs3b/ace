# Goal 6 — Analyze Consistency Report Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/06/analyze-consistency.stdout`, `.stderr`, and `.exit` exist.
2. `results/tc/06/analyze-consistency.exit` contains `0` or `1`.
3. If stdout includes `Report saved to:`, the referenced report file must exist.
4. If stdout includes `No documents found to analyze.`, treat it as a valid empty-scope terminal path when paired with explicit command evidence in stdout/stderr.
5. If exit is `1`, stderr or stdout must contain explicit failure evidence (for example no results returned or analysis/LLM failure details).
6. If stderr explicitly reports provider unavailability or authentication failure, treat that as valid constrained-environment failure evidence even when stdout does not contain a saved-report marker.

## Verdict

- **PASS**: Analyze-consistency artifacts exist and the recorded exit path has concrete evidence (saved-report, empty-scope, explicit failure, or explicit constrained-environment provider failure).
- **FAIL**: Missing artifacts, invalid exit code, or missing evidence for the recorded exit path.
