# Goal 1 Verification - Help surface for both binaries

## Expectation

Both executables return exit code `0` and expose their command surfaces.

## PASS Criteria

- `results/tc/01/models-help.exit` is `0`
- `results/tc/01/providers-help.exit` is `0`
- `results/tc/01/models-help.stdout` includes `COMMANDS`
- `results/tc/01/models-help.stdout` includes `EXAMPLES`
- `results/tc/01/providers-help.stdout` includes `COMMANDS`
- `results/tc/01/providers-help.stdout` includes `EXAMPLES`
