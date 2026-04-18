# Goal 6 Verification - Benchmark smoke

## Expectation

Benchmark mode succeeds for `exact`, `compact`, and `agent` and returns JSON output that references all
requested modes.

## PASS Criteria

- `results/tc/06/benchmark.exit` is `0`
- `results/tc/06/benchmark.stdout` includes `exact`
- `results/tc/06/benchmark.stdout` includes `compact`
- `results/tc/06/benchmark.stdout` includes `agent`
