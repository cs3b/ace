# Goal 3 — Park Idea Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/03/` includes park command captures.
2. Park command exits with code `0`.
3. Follow-up evidence shows lifecycle transition to parked state.

## Verdict

- **PASS**: Idea lifecycle transition to parked state is verified.
- **FAIL**: Transition evidence missing or command failed.
