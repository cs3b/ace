# Goal 4 — Output Format and Filtering Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **JSON report artifacts exist** — results/tc/04/ contains a JSON report copy.
2. **Valid JSON structure** — The report contains `tokens` and `scan_metadata` keys.
3. **Whitelist active** — The whitelist scan still detects non-whitelisted secrets (non-zero exit).
4. **Filtered results** — If whitelist scan details are available, test/ directory files are excluded from results.

## Verdict

- **PASS**: JSON report has valid structure, whitelist correctly filters while still detecting non-whitelisted secrets.
- **FAIL**: Invalid JSON, whitelist not working, or captures missing.

Report: `PASS` or `FAIL` with evidence (JSON structure, whitelist behavior).
