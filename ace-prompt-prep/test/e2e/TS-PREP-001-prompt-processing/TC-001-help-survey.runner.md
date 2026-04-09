# Goal 1 — Help Survey

## Goal

Capture the real `ace-prompt-prep` help surface and one command-specific help path.

## Capture

Save all output to `results/tc/01/`. Capture:
- `help.stdout`, `help.stderr`, `help.exit` from the primary help command
- `command-help.stdout`, `command-help.stderr`, `command-help.exit` from one discovered command-specific help path

## Constraints

- Use only `ace-prompt-prep` to gather information.
- Start with `--help` to discover the tool's interface. Do not assume flag names or subcommands.
- **Foundation for later goals**: These command captures are the reference for all subsequent goals. Later goals will build on the discovered interface and will not re-run `--help`.
