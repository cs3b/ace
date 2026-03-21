# Goal 1 — Help Survey

## Goal

Explore `ace-prompt-prep --help` and any subcommand help it provides. Summarize what the tool does, list its subcommands and their flags/options. Note anything that seems unclear, missing, or potentially confusing to a first-time user.

## Workspace

Save all output to `results/tc/01/`. Capture:
- `help.stdout`, `help.stderr`, `help.exit` from the primary help command
- `subcommands.md` summarizing discovered subcommands/flags
- `observations.md` with usability observations grounded in captured outputs

## Constraints

- Use only `ace-prompt-prep` to gather information. Do not create files manually or fabricate output.
- Start with `--help` to discover the tool's interface. Do not assume flag names or subcommands.
- Your observations file should reflect what the tool actually reports, not what you expect it to report.
- **Foundation for later goals**: Your observations here serve as the reference for all subsequent goals. Later goals will build on what you discover — they will not re-run `--help`.
