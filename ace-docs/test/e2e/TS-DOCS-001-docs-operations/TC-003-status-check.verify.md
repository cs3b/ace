# Goal 3 — Status Check Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. Seeded docs corpus is present (`docs/guide.md`, `docs/reference.md`) so status summarizes real managed docs.
2. `results/tc/03/status.stdout`, `.stderr`, and `.exit` exist.
3. `results/tc/03/status.exit` is `0`.
4. `results/tc/03/status.stdout` includes stable status semantics (managed docs/count-style sections or freshness categories), not exact summary wording.

## Verdict

- **PASS**: Seeded corpus and status captures are complete and show concrete docs health/summary semantics.
- **FAIL**: Missing seeded docs/captures, non-zero exit, or absent status-summary semantics.
