# Goal 3 — Status Check Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/03/status.stdout`, `.stderr`, and `.exit` exist.
2. `results/tc/03/status.exit` is `0`.
3. `results/tc/03/status.stdout` includes status-style summary indicators (for example `Managed Documents`, `Outdated`, or similar counts/health sections).
4. If fallback setup artifacts are present, they should be consistent with a seeded docs corpus; their absence alone is not a failure when status output already proves managed documents exist.

## Verdict

- **PASS**: Status captures are complete and show concrete docs health/summary output.
- **FAIL**: Missing captures, non-zero exit, or absent summary evidence.
