# Goal 3 - Providers list/show after public sync

## Goal

Sync cache through the public CLI path, then verify `ace-llm-providers list` and
`show` behavior through real CLI invocations.

## Workspace

Save artifacts to `results/tc/03/`.

Actions:
1. Set `XDG_CACHE_HOME` to `$(pwd)/results/tc/03/xdg-cache`.
2. Export `ACE_MODELS_FIXTURE_JSON` with fixture data containing providers
   `anthropic` and `openai` and at least one explicit model `id` each.
3. Run `ace-models sync` and capture stdout/stderr/exit to:
   - `results/tc/03/sync.stdout`
   - `results/tc/03/sync.stderr`
   - `results/tc/03/sync.exit`
4. Unset `ACE_MODELS_FIXTURE_JSON`.
5. Run `ace-llm-providers list` and capture stdout/stderr/exit to:
   - `results/tc/03/list.stdout`
   - `results/tc/03/list.stderr`
   - `results/tc/03/list.exit`
6. Run `ace-llm-providers show anthropic` and capture stdout/stderr/exit to:
   - `results/tc/03/show.stdout`
   - `results/tc/03/show.stderr`
   - `results/tc/03/show.exit`

## Constraints

- Keep all writes under `results/tc/03/`.
- Use real executable commands only.
