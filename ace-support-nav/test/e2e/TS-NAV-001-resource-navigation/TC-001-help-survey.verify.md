# Goal 1 — Help Survey and Actionable Discovery Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. **Observations file exists** — `results/tc/01/observations.md` is present.
2. **Substantive observations** — Observations include at least 4 non-empty lines and contain explicit discovery notes (not placeholder text).
3. **Protocol evidence present** — Observations name protocol-style examples discovered from help output (for example `guide://`, `wfi://`, `tmpl://`).
4. **Actionable journey documented** — Observations include a concrete follow-on command chain that can drive later goals (for example `resolve -> list/sources -> create`).
5. **Sources capture exists** — `results/tc/01/sources.stdout`, `.stderr`, and `.exit` are present.
6. **Sources command succeeded** — `results/tc/01/sources.exit` is `0`.
7. **Sources listing is substantive** — `results/tc/01/sources.stdout` includes source-list content (for example `Available sources:` or source alias rows).

## Verdict

- **PASS**: Observations are actionable and sources evidence confirms real command-surface discovery.
- **FAIL**: Missing observations/captures, non-actionable notes, or failed sources command.

Report: `PASS` or `FAIL` with evidence (quote relevant lines or note their absence).
