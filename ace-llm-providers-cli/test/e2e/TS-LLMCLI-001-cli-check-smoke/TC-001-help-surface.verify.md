# Goal 1 Verification - Help surface

## Expectation

`ace-llm-providers-cli-check --help` exits with code `0` and includes expected help text.

## PASS Criteria

- `results/tc/01/help.exit` is `0`
- `results/tc/01/help.stdout` includes `Usage: ace-llm-providers-cli-check`
- `results/tc/01/help.stdout` includes `Checks availability and authentication status of CLI-based LLM tools`
- `results/tc/01/help.stdout` includes `Exit codes:`
