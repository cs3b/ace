# Goal 4 — PR Summary Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/04/` contains PR-context command captures.
2. `pr.exit` and corresponding `pr.stdout|stderr` are present.
3. PASS path A: `pr.exit == 0` and output includes PR metadata fields.
4. PASS path B: `pr.exit != 0` with explicit no-PR context evidence and a
   successful fallback capture (`status-no-pr.exit == 0`).

## Verdict

- **PASS**: PR command succeeds with metadata OR fallback captures no-PR behavior explicitly.
- **FAIL**: Missing captures, ambiguous fallback, or both attempts fail.
