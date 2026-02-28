# Goal 3 — Move Idea to Maybe Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/03/` includes move command captures.
2. Move command exits with code `0`.
3. Follow-up evidence shows lifecycle transition to maybe folder (`_maybe/`).

## Verdict

- **PASS**: Idea lifecycle transition to maybe folder is verified.
- **FAIL**: Transition evidence missing or command failed.
