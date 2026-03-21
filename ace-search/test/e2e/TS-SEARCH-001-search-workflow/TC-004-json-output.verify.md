# Goal 4 — JSON Output Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. `results/tc/04/` contains JSON-mode command captures.
2. Exit code is successful.
3. `json-search.stdout` is structured JSON output (not plain grep-style text).
4. Evidence shows JSON includes search result payload details for at least one match.

## Verdict

- **PASS**: JSON mode emits parseable structured output with match evidence.
- **FAIL**: Output is not structured JSON, has no match payload evidence, or command failed.
