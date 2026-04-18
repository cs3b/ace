# Goal 5 — Analyze Document Drift Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/05/analyze.stdout`, `.stderr`, and `.exit` exist.
2. `results/tc/05/analyze.exit` contains one of `0`, `2`, or `3`.
3. If stdout contains `Results saved to:`, the referenced directory must contain `analysis.md` and `metadata.yml`.
4. If stdout indicates a no-changes outcome, accept it as a valid terminal path even when exit is `0` or `2`.
5. If exit is `3`, stderr must indicate analysis/LLM unavailability or execution failure.

## Verdict

- **PASS**: Analyze command artifacts exist and one valid contract path (saved-results/no-changes/analysis-error) is evidenced.
- **FAIL**: Missing artifacts, invalid exit code, or missing evidence for the recorded exit path.
