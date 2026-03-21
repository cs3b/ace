# Goal 1 — Content Search Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/01/` contains command captures.
2. Exit code is captured and successful.
3. Output includes matched content lines and file references.
4. Evidence cites `content-search.stdout` and `content-search.exit` specifically.

## Verdict

- **PASS**: Content search returns real matches with explicit stdout/exit evidence.
- **FAIL**: No match evidence or command failure.
