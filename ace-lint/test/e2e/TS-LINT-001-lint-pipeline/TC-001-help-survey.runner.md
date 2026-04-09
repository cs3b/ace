# Goal 1 — Help Survey

## Goal

Capture the real `ace-lint --help` surface.

## Capture

- `results/tc/01/help.stdout`
- `results/tc/01/help.stderr`
- `results/tc/01/help.exit`

## Constraints

- Use only `ace-lint` to gather information.
- Start with `--help` to discover the tool's interface. Do not assume flag names or options.
- **Foundation for later goals**: These command captures are the reference for all subsequent goals. Later goals will build on the discovered interface and will not re-run `--help`.
