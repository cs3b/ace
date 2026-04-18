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
4. **Config effect is observable** — `user-config.stdout` shows the configured format effect (for example JSON under `--verbose`).
5. **CLI override path executes** — override run completes and evidence indicates CLI flag precedence over config setting (for example config-driven JSON output followed by CLI-driven table/plain output).

## Verdict

- **PASS**: Focused precedence flow is demonstrated with concrete artifacts and no crashes.
- **FAIL**: Missing artifacts, crashes, or no evidence of CLI override precedence.

Report: `PASS` or `FAIL` with evidence.
