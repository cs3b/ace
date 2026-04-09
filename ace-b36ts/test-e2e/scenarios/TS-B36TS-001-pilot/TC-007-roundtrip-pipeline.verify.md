# Goal 7 — Roundtrip Pipeline Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. **Required artifacts exist** — `roundtrip.summary`, `roundtrip.stdout`, `roundtrip.stderr`, `roundtrip.exit`.
2. **Pipeline succeeded** — `roundtrip.exit` contains `0`.
3. **Three required fields present** — `roundtrip.summary` includes `ORIGINAL=`, `TOKEN=`, and `DECODED=` lines.
4. **Token validity** — `TOKEN` value matches `[0-9a-z]{2,8}`.
5. **Roundtrip semantic match** — `DECODED` reflects the original date (`2025-01-06`) in ISO-like output.

## Verdict

- **PASS**: Required artifacts exist, pipeline succeeds, valid token is present, and decoded output matches original date semantics.
- **FAIL**: Missing artifacts, non-zero exit, malformed fields, invalid token, or decoded mismatch.

Report: `PASS` or `FAIL` with evidence (summary fields and exit-code content).
