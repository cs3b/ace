# Goal 3 — Complete Task Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/03/` includes done and show captures.
2. Done command exits with code `0`.
3. Show output indicates task status is `done`.
4. Task ID matches the ID tracked from Goal 1.

## Verdict

- **PASS**: Completion flow updated the same task to `done`.
- **FAIL**: Missing evidence or status is not `done`.
