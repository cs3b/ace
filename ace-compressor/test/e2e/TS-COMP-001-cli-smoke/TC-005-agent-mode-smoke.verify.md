# Goal 5 Verification - Agent mode smoke

## Expectation

Agent mode succeeds and emits ContextPack output tagged with `agent`.

## PASS Criteria

- `results/tc/05/agent.exit` is `0`
- `results/tc/05/agent.stdout` includes `H|ContextPack/3|agent`
- `results/tc/05/agent.stdout` includes `FILE|`
