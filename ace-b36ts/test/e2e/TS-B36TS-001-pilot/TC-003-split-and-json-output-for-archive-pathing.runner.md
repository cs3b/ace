# Goal 3 - Split and JSON Output for Archive Pathing

## Goal

Use split/path/json CLI options to validate archive-oriented output workflows
from the public `ace-b36ts encode` interface.

## Workspace

Save command captures to `results/tc/03/`.

## Constraints

- Use only documented `ace-b36ts encode` options from usage/help.
- Capture stdout/stderr/exit for each command.
- Do not invent expected strings; use real command outputs.

## Steps

1. Run `ace-b36ts encode "2026-03-21 00:00:00 UTC" --split month,week,day` and save `split.*`.
2. Run `ace-b36ts encode "2026-03-21 00:00:00 UTC" --split month,week,day --path-only` and save `path-only.*`.
3. Run `ace-b36ts encode "2026-03-21 00:00:00 UTC" --split month,week,day --json` and save `json.*`.
4. In runner observations, summarize how split/path/json outputs can support archive path decisions.
