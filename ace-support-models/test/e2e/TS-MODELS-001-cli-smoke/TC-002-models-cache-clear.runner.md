# Goal 2 - Cache clear lifecycle for ace-models

## Goal

Seed cache files, run `ace-models clear`, and capture evidence that cache files
were deleted through real CLI execution.

## Workspace

Save artifacts to `results/tc/02/`.

Actions:
1. Set `XDG_CACHE_HOME` to `$(pwd)/results/tc/02/xdg-cache`.
2. Create `${XDG_CACHE_HOME}/ace-models/api.json` and `metadata.json` with sample JSON.
3. Record pre-state file listing to `results/tc/02/pre-cache-state.txt`.
4. Run `ace-models clear` and capture stdout/stderr/exit as:
   - `results/tc/02/clear.stdout`
   - `results/tc/02/clear.stderr`
   - `results/tc/02/clear.exit`
5. Record post-state file listing to `results/tc/02/post-cache-state.txt`.

## Constraints

- Do not use library imports.
- Keep all writes under `results/tc/02/`.
