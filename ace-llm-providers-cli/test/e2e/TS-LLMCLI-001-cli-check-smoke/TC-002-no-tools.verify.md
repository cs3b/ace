# Goal 2 Verification - No-tools deterministic path

## Expectation

When provider binaries are absent from PATH, the CLI reports unavailable providers and exits with code `1`.

## PASS Criteria

- `results/tc/02/no-tools.exit` is `1`
- `results/tc/02/no-tools.stdout` includes `Summary:`
- `results/tc/02/no-tools.stdout` includes `Available: 0/4 CLI tools installed`
- `results/tc/02/no-tools.stdout` includes `To use CLI providers, install at least one tool from above`
