# Goal 1 — Help Survey Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Help captures exist** — `help.stdout`, `help.stderr`, and `help.exit` are present.
2. **Help succeeded** — `help.exit` reports success.
3. **Mentions key concepts** — `help.stdout` references presets, output modes, or bundling behavior.

## Verdict

- **PASS**: The help command succeeds and exposes the expected `ace-bundle` command surface.
- **FAIL**: Captures are missing, help fails, or key concepts are not evidenced.

Report: `PASS` or `FAIL` with evidence from `help.*`.
