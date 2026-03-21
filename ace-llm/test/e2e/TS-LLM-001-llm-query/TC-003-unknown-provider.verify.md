# Goal 3 — Unknown Provider Routing Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/03/` contains command captures including at least one `*.stdout`,
   one `*.stderr`, and one `*.exit` file.
2. Exit code evidence is explicit and numeric in `*.exit`.
3. Evidence shows an explicit unknown-provider / unsupported-provider routing
   error for `nope`, not a generic infrastructure failure.

## Verdict

- **PASS**: Artifacts demonstrate deterministic routing rejection for unsupported provider.
- **FAIL**: Missing captures or error evidence does not show unknown-provider routing.
