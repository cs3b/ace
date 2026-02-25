# Goal 4 — List Tasks Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/04/` contains list command captures.
2. Exit code is `0`.
3. Output includes the tracked task ID/title.
4. Output reflects a completed (`done`) state.

## Verdict

- **PASS**: List output correctly shows the completed task.
- **FAIL**: Task missing from list or state does not match.
