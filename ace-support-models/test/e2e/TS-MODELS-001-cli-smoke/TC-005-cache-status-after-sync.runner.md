# Goal 5 - Cache status after sync

## Goal

Run public sync with deterministic fixture data, then capture `ace-models status`
output to verify user-visible cache status semantics.

## Workspace

Save artifacts to `results/tc/05/`.

Actions:
1. Set `XDG_CACHE_HOME` to `$(pwd)/results/tc/05/xdg-cache`.
2. Export `ACE_MODELS_FIXTURE_JSON` with fixture data containing at least one
   provider and model id.
3. Run `ace-models sync` and capture stdout/stderr/exit to:
   - `results/tc/05/sync.stdout`
   - `results/tc/05/sync.stderr`
   - `results/tc/05/sync.exit`
4. Unset `ACE_MODELS_FIXTURE_JSON`.
5. Run `ace-models status` and capture stdout/stderr/exit to:
   - `results/tc/05/status.stdout`
   - `results/tc/05/status.stderr`
   - `results/tc/05/status.exit`

## Constraints

- Keep all writes under `results/tc/05/`.
- Use real executable commands only.
