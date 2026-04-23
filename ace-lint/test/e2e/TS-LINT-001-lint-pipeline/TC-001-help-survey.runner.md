# Goal 1 — Public Surface Survey

## Goal

Capture the retained public surface for this scenario using `ace-lint --help`. Preserve the command output that later goals rely on for `--fix`, `--no-report`, `--validators`, and `--doctor`.

## Workspace

Save all output to `results/tc/01/`:
- `results/tc/01/help.stdout`, `.stderr`, `.exit` from `ace-lint --help`

## Constraints

- Use only `ace-lint --help` for discovery. Do not use hidden recipes.
- Start with `--help` to discover the tool's interface. Do not assume flag names or options.
- The preserved help output should reflect what the CLI actually reports, not assumptions.
- **Foundation for later goals**: This help capture is the retained public-surface reference for subsequent goals.
