# Goal 1 — Discover Docs Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/01/discover.stdout`, `.stderr`, and `.exit` exist.
2. `results/tc/01/discover.exit` contains `0`.
3. `results/tc/01/discover.stdout` contains evidence of document discovery (for example `Found` and at least one docs path).
4. Setup artifacts `results/tc/01/setup.stdout`, `.stderr`, `.exit` exist to prove the docs corpus was seeded.

## Verdict

- **PASS**: Discover capture files exist, command succeeded, and output shows managed-document listing evidence.
- **FAIL**: Missing capture files, non-zero exit, or no concrete discovery evidence.
