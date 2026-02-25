# Goal 7 — Configuration Cascade Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **All four capture sets exist** — results/tc/07/ contains captures for defaults, user-config, cli-override, and empty-config.
2. **Defaults work** — Scan completes (any exit code) without crashing when no user config exists.
3. **User config applied** — Scan completes when user config is present.
4. **CLI override works** — Scan completes when CLI flag overrides config.
5. **Empty config graceful** — Scan does not crash on empty config file.

## Verdict

- **PASS**: All four config scenarios complete without crashing. Tool works with defaults, respects user config, and handles empty configs gracefully.
- **FAIL**: Any scenario crashes, or captures missing.

Report: `PASS` or `FAIL` with evidence (exit codes, output snippets from each scenario).
