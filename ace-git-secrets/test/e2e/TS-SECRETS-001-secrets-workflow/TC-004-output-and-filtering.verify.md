# Goal 4 — Output Report + Whitelist Impact Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. **Saved report artifacts exist** — `saved-report.path` and `saved-report.json` are present.
2. **Saved report structure is valid** — `saved-report.json` includes `tokens` and `scan_metadata` keys.
3. **Whitelist config is explicit** — `whitelist-config.yml` includes a file rule for `test/**`.
4. **Whitelist behavior preserves true findings** — whitelist scan exit remains non-zero and evidence indicates non-whitelisted secret detection still occurs.
5. **Whitelist behavior evidence is explicit** — whitelist scan artifacts show that `test/mock_tokens.json` is no longer reported while a non-whitelisted finding such as `config.env` still remains.

## Verdict

- **PASS**: Saved report contract is valid and whitelist impact is demonstrated without masking non-whitelisted findings.
- **FAIL**: Missing/invalid saved report, missing whitelist config evidence, or incorrect whitelist behavior.

Report: `PASS` or `FAIL` with evidence.
