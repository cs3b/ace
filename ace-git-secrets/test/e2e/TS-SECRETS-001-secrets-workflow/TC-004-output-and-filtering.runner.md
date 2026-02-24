# Goal 4 — Output Format and Filtering

## Goal

Test two features: (1) JSON output format generates a valid report with expected structure, and (2) whitelist configuration excludes specified files from scan results while still detecting non-whitelisted secrets.

## Workspace

Save all output to `results/tc/04/`. Capture:
- `results/tc/04/json-report.stdout`, `.stderr`, `.exit` — JSON format scan
- A copy of the generated JSON report file
- `results/tc/04/whitelist-scan.stdout`, `.stderr`, `.exit` — scan with whitelist config

## Constraints

- For JSON output: use the scan command with JSON format flag discovered in Goal 1.
- For whitelist: create a config that excludes the `test/` directory, then scan.
- The sandbox has `test/mock_tokens.json` (should be excluded by whitelist) and `config.env` (should still be detected).
- All artifacts must come from real tool execution, not fabricated.
