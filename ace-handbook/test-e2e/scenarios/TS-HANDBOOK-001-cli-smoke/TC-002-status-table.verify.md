# Goal 2 Verification - Status table output

## Expectation

`ace-handbook status --provider pi` exits successfully and prints tabular status output.

## PASS Criteria

- `results/tc/02/status-table.exit` is `0`
- `results/tc/02/status-table.stdout` includes `provider`
- `results/tc/02/status-table.stdout` includes `pi`
