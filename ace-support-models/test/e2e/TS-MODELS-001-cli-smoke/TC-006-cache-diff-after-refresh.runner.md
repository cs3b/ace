# Goal 6 - Cache diff after refresh

## Goal

Run two public sync operations with different deterministic fixture payloads and
capture `ace-models diff` output.

## Workspace

Save artifacts to `results/tc/06/`.

Actions:
1. Set `XDG_CACHE_HOME` to `$(pwd)/results/tc/06/xdg-cache`.
2. Export initial `ACE_MODELS_FIXTURE_JSON` payload with provider/model data.
3. Run `ace-models sync` and capture stdout/stderr/exit to:
   - `results/tc/06/sync-initial.stdout`
   - `results/tc/06/sync-initial.stderr`
   - `results/tc/06/sync-initial.exit`
4. Export updated `ACE_MODELS_FIXTURE_JSON` payload that changes model set for at
   least one provider.
5. Run `ace-models sync --force` and capture stdout/stderr/exit to:
   - `results/tc/06/sync-refresh.stdout`
   - `results/tc/06/sync-refresh.stderr`
   - `results/tc/06/sync-refresh.exit`
6. Unset `ACE_MODELS_FIXTURE_JSON`.
7. Run `ace-models diff` and capture stdout/stderr/exit to:
   - `results/tc/06/diff.stdout`
   - `results/tc/06/diff.stderr`
   - `results/tc/06/diff.exit`

## Constraints

- Keep all writes under `results/tc/06/`.
- Use real executable commands only.
