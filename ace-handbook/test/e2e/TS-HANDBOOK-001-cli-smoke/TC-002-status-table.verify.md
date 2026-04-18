# Goal 2 Verification - Status table output

## Expectation

`ace-handbook status --provider pi` exits successfully and prints tabular status output.

## Oracle Priority

1. User-visible status table contract in `results/tc/02/status-table.stdout`
2. Explicit command exit artifact `results/tc/02/status-table.exit`
3. Debug fallback captures only when primary artifacts are ambiguous

## PASS Criteria

- `results/tc/02/status-table.exit` is `0`
- `results/tc/02/status-table.stdout` includes `provider` table header text
- `results/tc/02/status-table.stdout` includes `pi`
- `results/tc/02/status-table.stdout` includes `.pi/skills`
