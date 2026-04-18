# Goal 3 Verification - Status JSON output

## Expectation

`ace-handbook status --provider pi --format json` exits successfully and emits JSON status data.

## Oracle Priority

1. JSON payload contract in `results/tc/03/status-json.stdout`
2. Explicit command exit artifact `results/tc/03/status-json.exit`
3. Debug fallback captures only when primary artifacts are ambiguous

## PASS Criteria

- `results/tc/03/status-json.exit` is `0`
- `results/tc/03/status-json.stdout` is valid JSON object text
- JSON includes top-level key `"canonical"` with numeric `"total"`
- JSON includes top-level key `"providers"` with array value
- JSON `providers` includes an entry with `"provider": "pi"`
