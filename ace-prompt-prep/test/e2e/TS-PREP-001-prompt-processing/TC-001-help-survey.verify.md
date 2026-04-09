# Goal 1 — Help Survey Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
4. **Primary captures exist** — `help.*` and `command-help.*` exist in `results/tc/01/`.
5. **Help succeeded** — `help.exit` and `command-help.exit` report `0`.
6. **Root help exposes command surface** — `help.stdout` references a command path that matches the command-specific help capture.
7. **Command-specific help is present** — `command-help.stdout` contains usage or option text beyond the root help banner.

## Verdict

- **PASS**: The help captures exist, succeed, and expose both the root and command-specific help surface.
- **FAIL**: Captures are missing, commands fail, or the command-specific help path is not evidenced.

Report: `PASS` or `FAIL` with evidence from the help captures.
