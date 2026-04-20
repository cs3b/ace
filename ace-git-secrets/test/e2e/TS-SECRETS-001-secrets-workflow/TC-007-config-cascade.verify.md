# Goal 7 — Configuration Cascade (Focused) Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. **Focused artifact set exists** — defaults, user-config, and cli-override captures are present, plus `user-config.yml`.
2. **Defaults path executes** — baseline run completes without crash.
3. **User config path executes** — run with config completes without crash.
4. **Config effect is observable** — `user-config.stdout` shows the configured format effect, for example JSON under `--verbose` with top-level keys such as `scan_metadata`, `summary`, or `tokens`.
5. **CLI override path executes** — override run completes and evidence indicates CLI flag precedence over config setting.
6. **Output formats differ visibly** — treat `cli-override.stdout` as table/plain output when it contains table-style text such as `Scan Report:`, `Summary:`, or `Detected Tokens:` even if individual token details are verbose. This contrasts with `user-config.stdout` JSON and is sufficient override evidence.

## Verdict

- **PASS**: Focused precedence flow is demonstrated with concrete artifacts and no crashes, including a visible JSON-vs-table/plain stdout difference.
- **FAIL**: Missing artifacts, crashes, or no evidence of CLI override precedence.

Report: `PASS` or `FAIL` with evidence.
