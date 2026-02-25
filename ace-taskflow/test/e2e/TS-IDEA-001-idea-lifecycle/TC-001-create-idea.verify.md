# Goal 1 — Create Idea Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/01/` contains create command captures.
2. Exit code is `0`.
3. Artifacts include created idea reference or path details.

## Verdict

- **PASS**: Idea creation evidence is present and complete.
- **FAIL**: Missing captures or no creation proof.
