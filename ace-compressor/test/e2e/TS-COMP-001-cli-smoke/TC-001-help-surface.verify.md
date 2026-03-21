# Goal 1 Verification - Help surface for ace-compressor

## Expectation

The binary returns exit code `0` and exposes documented CLI options.

## PASS Criteria

- `results/tc/01/help.exit` is `0`
- `results/tc/01/help.stdout` includes `ace-compressor`
- `results/tc/01/help.stdout` includes `--mode`
- `results/tc/01/help.stdout` includes `--source-scope`
