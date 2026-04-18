# Goal 1 — Help Survey and Actionable Discovery

## Goal

Use `ace-nav --help` (and command help as needed) to discover practical commands and protocols, then produce observations that can directly drive later goals. Capture `ace-nav sources` output as concrete command-surface evidence.

## Workspace

Save all output to `results/tc/01/`.

Required artifacts:
- `results/tc/01/observations.md` — concise findings from help output, including at least one actionable command chain for later goals
- `results/tc/01/sources.stdout`
- `results/tc/01/sources.stderr`
- `results/tc/01/sources.exit`

## Constraints

- Use only `ace-nav` commands.
- Start with `ace-nav --help`; avoid assumptions not supported by help text.
- Observations must include:
  - supported protocol examples discovered from help
  - at least one command sequence that will be used later (for example `resolve` then `list`/`sources`, then `create`)
- All captures must come from real execution output.
