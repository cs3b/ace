# Goal 1 — Help Survey

## Goal

Capture the real `ace-nav` help surface and the `sources` listing output.

## Capture

- `results/tc/01/help.stdout`
- `results/tc/01/help.stderr`
- `results/tc/01/help.exit`
- `results/tc/01/sources.stdout`
- `results/tc/01/sources.stderr`
- `results/tc/01/sources.exit`

## Constraints

- Use only `ace-nav` to gather information.
- Start with `--help` to discover the tool's interface. Do not assume flag names or protocols.
- Run `ace-nav sources` after the help survey and persist raw captures to the files above.
- **Foundation for later goals**: Your observations here serve as the reference for all subsequent goals. Later goals will build on what you discover — they will not re-run `--help`.
