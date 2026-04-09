# Goal 1 — Help Survey Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
- Confirm sandbox/project state impact first.
- Confirm explicit artifacts under `results/tc/{NN}/`.
- Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

Checks:
1. **Help captures exist** — `help.stdout`, `help.stderr`, and `help.exit` are present.
2. **Help succeeded** — `help.exit` reports success.
3. **Mentions subcommands** — `help.stdout` references at least two of: work-on, status, prune.

## Verdict

- **PASS**: The help command succeeds and exposes the expected overseer command surface.
- **FAIL**: Captures are missing, help fails, or key subcommands are not evidenced.

Report: `PASS` or `FAIL` with evidence from `help.*`.
