# Goal 1 — Help Survey Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
4. **Primary captures exist** — `help.stdout`, `help.stderr`, and `help.exit` exist in `results/tc/01/`.
5. **Help succeeded** — `help.exit` reports `0`.
6. **Subcommands documented** — `subcommands.md` references concrete commands or flags from `help.stdout`.
7. **Observations present** — `observations.md` contains at least one assessment grounded in captured help output.

## Verdict

- **PASS**: All expectations met. File exists with substantive observations about the tool's help interface.
- **FAIL**: File missing, empty, boilerplate-only, or lacks any mention of tool subcommands/flags.

Report: `PASS` or `FAIL` with evidence (cite filenames and relevant lines or note their absence).
