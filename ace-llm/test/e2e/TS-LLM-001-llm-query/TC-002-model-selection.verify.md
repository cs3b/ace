# Goal 2 — Model Selection Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/02/` contains command captures.
2. Exit code is recorded.
3. Evidence indicates selected model handling (success or explicit rejection).
4. Output format behavior (`json`) is reflected in artifact content.

## Verdict

- **PASS**: Model-selection behavior is demonstrably captured.
- **FAIL**: No evidence of routing/format handling.
