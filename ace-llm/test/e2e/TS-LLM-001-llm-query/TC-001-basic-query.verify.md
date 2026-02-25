# Goal 1 — Basic Query Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/01/` contains command captures.
2. Exit code is captured.
3. Output shows either a valid model response or a clear provider auth/config
   error message.

## Verdict

- **PASS**: Artifacts clearly show real execution outcome.
- **FAIL**: Missing captures or ambiguous/no output.
