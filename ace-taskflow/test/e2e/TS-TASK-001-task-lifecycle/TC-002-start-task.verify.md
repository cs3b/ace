# Goal 2 — Start Task Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/02/` has start and show command captures.
2. Start command exit code is `0`.
3. Show output demonstrates `in-progress` state.
4. Evidence references the same task ID created in Goal 1.

## Verdict

- **PASS**: Task state transitioned to `in-progress` for the same task.
- **FAIL**: Transition proof missing or mismatched task ID.
