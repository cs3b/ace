# Goal 3 Verification - Status JSON output

## Expectation

`ace-handbook status --provider pi --format json` exits successfully and emits JSON status data.

## PASS Criteria

- `results/tc/03/status-json.exit` is `0`
- `results/tc/03/status-json.stdout` includes `"canonical"`
- `results/tc/03/status-json.stdout` includes `"providers"`
- `results/tc/03/status-json.stdout` includes `"pi"`
