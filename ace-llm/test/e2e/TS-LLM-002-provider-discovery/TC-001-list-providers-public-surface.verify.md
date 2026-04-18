# Goal 1 — List Providers Public Surface Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. `results/tc/01/` contains command captures including at least one `*.stdout`,
   one `*.stderr`, and one `*.exit` file.
2. Exit code evidence is explicit and numeric in `*.exit`.
3. `*.stdout` includes provider-discovery surface text (for example an
   "Available LLM Providers" header, provider rows, setup hints, or inactive-provider section).
4. Evidence corresponds to the Goal 1 command and not unrelated setup output.

## Verdict

- **PASS**: Provider-discovery behavior is captured through explicit CLI output evidence.
- **FAIL**: Artifacts do not show the public provider-discovery surface.
