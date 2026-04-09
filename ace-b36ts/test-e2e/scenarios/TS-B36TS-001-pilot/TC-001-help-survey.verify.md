# Goal 1 — Help Survey Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Help captures exist** — `help.*`, `encode-help.*`, and `decode-help.*` are present.
2. **Help commands succeeded** — all three `.exit` files report success.
3. **Root help exposes command surface** — `help.stdout` mentions `encode` and `decode`.
4. **Subcommand help is specific** — `encode-help.stdout` and `decode-help.stdout` contain command-specific usage or option text beyond the root help banner.

## Verdict

- **PASS**: The command captures exist, succeed, and expose the expected root and subcommand help surface.
- **FAIL**: Captures are missing, exits fail, or the help surface does not show the expected commands.

Report: `PASS` or `FAIL` with evidence from the relevant help captures.
