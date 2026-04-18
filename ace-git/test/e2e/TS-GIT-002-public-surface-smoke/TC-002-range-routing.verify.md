# Goal 2 - Range Routing to Diff Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. `results/tc/02/` contains:
   - `range.stdout`
   - `range.stderr`
   - `range.exit`
2. Exit code is `0`.
3. `range.stdout` includes diff-oriented output evidence (for example unified diff markers like `diff --git`, `@@`, or file hunk lines).

## Verdict

- **PASS**: Range shorthand executes successfully and returns diff-style output.
- **FAIL**: Missing artifacts, non-zero exit, or no diff-style evidence.
