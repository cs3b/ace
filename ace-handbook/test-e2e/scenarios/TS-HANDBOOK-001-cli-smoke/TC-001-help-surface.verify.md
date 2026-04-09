# Goal 1 Verification - Help surface

## Expectation

`ace-handbook --help` exits with code `0` and includes the command surface.

## PASS Criteria

- `results/tc/01/help.exit` is `0`
- `results/tc/01/help.stdout` includes `COMMANDS`
- `results/tc/01/help.stdout` includes `sync`
- `results/tc/01/help.stdout` includes `status`
- `results/tc/01/help.stdout` includes `EXAMPLES`
