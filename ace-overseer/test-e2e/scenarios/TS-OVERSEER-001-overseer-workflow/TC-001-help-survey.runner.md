# Goal 1 — Help Survey

## Goal

Capture the real `ace-overseer --help` surface.

## Capture

- `results/tc/01/help.stdout`
- `results/tc/01/help.stderr`
- `results/tc/01/help.exit`

## Constraints

- Use only `ace-overseer` to gather information.
- Start with `--help` to discover the tool's interface. Do not assume subcommand names or flags.
- **Foundation for later goals**: These command captures are the reference for all subsequent goals.
