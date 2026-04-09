# Goal 1 — Help Survey Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Help and sources captures exist** — `help.*` and `sources.*` are present in `results/tc/01/`.
2. **Commands succeeded** — `help.exit` and `sources.exit` are `0`.
3. **Help mentions protocol-oriented usage** — `help.stdout` references protocol-style inputs or known protocol strings such as `guide://`, `wfi://`, or `tmpl://`.
4. **Sources listing is substantive** — `sources.stdout` includes `Available sources:` and at least one source alias entry.

## Verdict

- **PASS**: The help and sources commands both succeed and expose the expected navigation surface.
- **FAIL**: Captures are missing, commands fail, or the protocol/source surface is not evidenced.

Report: `PASS` or `FAIL` with evidence from `help.*` and `sources.*`.
