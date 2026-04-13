# Goal 6 — Status JSON Without PR Lookups Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/06/` contains:
   - `status-json-no-pr.stdout`
   - `status-json-no-pr.stderr`
   - `status-json-no-pr.exit`
2. Exit code is `0`.
3. `status-json-no-pr.stdout` is valid JSON and includes baseline repo keys such
   as `branch` and `repository_type`.

## Verdict

- **PASS**: JSON no-pr status output is valid and structurally complete.
- **FAIL**: Invalid JSON, missing key fields, or command failure.
