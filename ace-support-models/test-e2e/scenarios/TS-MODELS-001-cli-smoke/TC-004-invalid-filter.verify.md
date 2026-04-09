# Goal 4 Verification - Invalid filter error semantics

## Expectation

Invalid filter syntax returns a non-zero exit code and a clear validation error.

## PASS Criteria

- `results/tc/04/invalid-filter.exit` is non-zero
- `results/tc/04/invalid-filter.stderr` includes `Invalid filter format`
- `results/tc/04/invalid-filter.stderr` includes `Invalid model search filters`
