# Goal 1 — Help Survey

## Goal

Survey the real `ace-b36ts` help surface: root help plus the encode and decode command help.

## Capture

- `results/tc/01/help.stdout`
- `results/tc/01/help.stderr`
- `results/tc/01/help.exit`
- `results/tc/01/encode-help.stdout`
- `results/tc/01/encode-help.stderr`
- `results/tc/01/encode-help.exit`
- `results/tc/01/decode-help.stdout`
- `results/tc/01/decode-help.stderr`
- `results/tc/01/decode-help.exit`

## Constraints

- Use only `ace-b36ts` to gather information.
- Start with `--help` to discover the tool's interface. Do not assume flag names or subcommands.
- **Foundation for later goals**: Your observations here serve as the reference for all subsequent goals. Later goals will build on what you discover — they will not re-run `--help`.
