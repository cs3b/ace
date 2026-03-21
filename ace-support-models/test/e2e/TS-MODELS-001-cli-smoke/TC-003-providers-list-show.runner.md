# Goal 3 - Providers list/show with seeded cache

## Goal

Seed cache data and verify `ace-llm-providers list` and `show` behavior through
real CLI invocations.

## Workspace

Save artifacts to `results/tc/03/`.

Actions:
1. Set `XDG_CACHE_HOME` to `$(pwd)/results/tc/03/xdg-cache`.
2. Write `${XDG_CACHE_HOME}/ace-models/api.json` containing providers `anthropic`
   and `openai` with at least one model each.
3. Run `ace-llm-providers list` and capture stdout/stderr/exit to:
   - `results/tc/03/list.stdout`
   - `results/tc/03/list.stderr`
   - `results/tc/03/list.exit`
4. Run `ace-llm-providers show anthropic` and capture stdout/stderr/exit to:
   - `results/tc/03/show.stdout`
   - `results/tc/03/show.stderr`
   - `results/tc/03/show.exit`

## Constraints

- Keep all writes under `results/tc/03/`.
- Use real executable commands only.
