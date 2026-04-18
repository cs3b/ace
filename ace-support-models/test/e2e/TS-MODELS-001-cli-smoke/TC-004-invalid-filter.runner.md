# Goal 4 - Invalid filter error semantics

## Goal

Run an invalid filter invocation and capture operator-visible failure semantics
(exit code + stderr message).

## Workspace

Save artifacts to `results/tc/04/`.

Actions:
1. Set `XDG_CACHE_HOME` to `$(pwd)/results/tc/04/xdg-cache`.
2. Ensure `${XDG_CACHE_HOME}` exists.
3. Run `ace-models search -f badfilter`.
4. Capture stdout/stderr/exit to:
   - `results/tc/04/invalid-filter.stdout`
   - `results/tc/04/invalid-filter.stderr`
   - `results/tc/04/invalid-filter.exit`

## Constraints

- This goal is expected to fail; still capture all outputs.
- Keep all writes under `results/tc/04/`.
