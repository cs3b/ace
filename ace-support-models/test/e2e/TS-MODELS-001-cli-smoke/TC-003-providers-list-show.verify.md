# Goal 3 Verification - Providers list/show with seeded cache

## Expectation

With seeded cache data, `ace-llm-providers list` and `show anthropic` succeed
and emit provider/model details.

## PASS Criteria

- `results/tc/03/list.exit` is `0`
- `results/tc/03/show.exit` is `0`
- `results/tc/03/list.stdout` includes `Providers (`
- `results/tc/03/list.stdout` includes `anthropic`
- `results/tc/03/show.stdout` includes `Provider: anthropic`
- `results/tc/03/show.stdout` includes at least one seeded model id
