# Goal 1 - Help surface

## Goal

Run the CLI help command and capture command-surface behavior.

## Workspace

Save artifacts to `results/tc/01/`.

Capture:
- `results/tc/01/help.stdout`, `.stderr`, `.exit` from `./ace-llm-providers-cli/exe/ace-llm-providers-cli-check --help`

## Constraints

- Use only local executable invocation via the package CLI entrypoint.
- Capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/01/`.
