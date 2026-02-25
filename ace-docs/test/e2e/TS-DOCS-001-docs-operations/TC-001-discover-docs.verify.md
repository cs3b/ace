# Goal 1 — Discover Docs Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/01/` contains discover command captures.
2. Exit code is successful.
3. Output includes document discovery/listing evidence.

## Verdict

- **PASS**: Discover command returns usable traversal output.
- **FAIL**: Missing discovery evidence or command failure.
