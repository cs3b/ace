# Goal 1 - Help Surface Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. `results/tc/01/` contains:
   - `help.stdout`
   - `help.stderr`
   - `help.exit`
2. Exit code is `0`.
3. `help.stdout` includes command-level public surface entries such as `diff`, `status`, and `pr`.

## Verdict

- **PASS**: Help command returns successfully with expected public command surface.
- **FAIL**: Missing artifacts, non-zero exit, or missing command surface evidence.
