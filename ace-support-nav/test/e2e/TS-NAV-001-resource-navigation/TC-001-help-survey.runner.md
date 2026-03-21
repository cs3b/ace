# Goal 1 — Help Survey

## Goal

Explore `ace-nav --help` and any subcommand help it provides. Summarize what the tool does, list its supported protocols (e.g., guide://, wfi://, tmpl://), flags, and options. Note the extension inference behavior and any configuration options mentioned. Also run `ace-nav sources` to capture source listing output as command-surface evidence.

## Workspace

Save all output to `results/tc/01/`. Write an observations file summarizing your findings.

Capture `ace-nav sources` command output:
- `results/tc/01/sources.stdout`
- `results/tc/01/sources.stderr`
- `results/tc/01/sources.exit`

## Constraints

- Use only `ace-nav` to gather information. Do not create files manually or fabricate output.
- Start with `--help` to discover the tool's interface. Do not assume flag names or protocols.
- Run `ace-nav sources` after the help survey and persist raw captures to the files above.
- Your observations file should reflect what the tool actually reports, not what you expect it to report.
- **Foundation for later goals**: Your observations here serve as the reference for all subsequent goals. Later goals will build on what you discover — they will not re-run `--help`.
