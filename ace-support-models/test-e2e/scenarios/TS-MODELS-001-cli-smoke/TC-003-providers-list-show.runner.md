# Goal 3 - Providers list/show with seeded cache

## Goal

Seed cache data and verify `ace-llm-providers list` and `show` behavior through
real CLI invocations.

## Workspace

Save artifacts to `results/tc/03/`.

Actions:
1. Set `XDG_CACHE_HOME` to `$(pwd)/results/tc/03/xdg-cache`.
2. Write `${XDG_CACHE_HOME}/ace-models/api.json` in the wrapped cache shape used by provider command coverage:
   - top-level `"providers"` object
   - provider keys `anthropic` and `openai`
   - each provider has a `"models"` object keyed by model id
3. Capture the seeded cache file and environment proof:
   - `results/tc/03/api.json`
   - `results/tc/03/env.stdout`
4. Run `ace-llm-providers list` with that `XDG_CACHE_HOME` binding and capture stdout/stderr/exit to:
   - `results/tc/03/list.stdout`
   - `results/tc/03/list.stderr`
   - `results/tc/03/list.exit`
5. Run `ace-llm-providers show anthropic` with that same `XDG_CACHE_HOME` binding and capture stdout/stderr/exit to:
   - `results/tc/03/show.stdout`
   - `results/tc/03/show.stderr`
   - `results/tc/03/show.exit`

## Constraints

- Keep all writes under `results/tc/03/`.
- Use real executable commands only.
- `env.stdout` must prove the commands saw the intended `XDG_CACHE_HOME` and cache file path before evaluating list/show output.
