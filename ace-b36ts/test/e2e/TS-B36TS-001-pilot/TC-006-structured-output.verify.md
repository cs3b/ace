# Goal 6 — Structured Output Integration Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. **Required artifacts exist** — `encode.json`, `jq-length.txt`, `jq-first.txt`, and `integration-notes.md` exist.
2. **JSON is valid and non-empty** — `encode.json` parses as JSON and contains at least one ID.
3. **jq extraction evidence** — `jq-length.txt` contains a positive integer and `jq-first.txt` contains a token-like value.
4. **Direct-consumption narrative** — `integration-notes.md` explains that `jq` consumed tool output directly.

## Verdict

- **PASS**: Required artifacts exist, JSON is valid, jq extraction succeeded, and notes confirm direct integration.
- **FAIL**: Missing artifacts, invalid/empty JSON, failed extraction evidence, or no integration explanation.

Report: `PASS` or `FAIL` with evidence (artifact names and relevant snippets).
