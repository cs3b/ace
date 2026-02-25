# Goal 2 — List Ideas Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. List command captures exist in `results/tc/02/`.
2. Exit code is `0`.
3. Output includes the idea created in Goal 1.

## Verdict

- **PASS**: Listing includes expected created idea.
- **FAIL**: Created idea absent or command failed.
