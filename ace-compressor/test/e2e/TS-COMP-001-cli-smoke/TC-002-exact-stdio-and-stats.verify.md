# Goal 2 Verification - Exact mode stdio and stats smoke

## Expectation

Exact mode succeeds, emits ContextPack output on stdio, and reports stats including output path and source count.

## PASS Criteria

- `results/tc/02/exact-stdio.exit` is `0`
- `results/tc/02/exact-stdio.stdout` includes `H|ContextPack/3|exact`
- `results/tc/02/exact-stdio.stdout` includes `SEC|`
- `results/tc/02/exact-stats.exit` is `0`
- `results/tc/02/exact-stats.stdout` includes `Mode:     exact`
- `results/tc/02/exact-stats.stdout` includes `Output:`
- `results/tc/02/exact-stats.stdout` includes `.ace-local/compressor/`
- `results/tc/02/exact-stats.stdout` includes `Sources:  1 file`
