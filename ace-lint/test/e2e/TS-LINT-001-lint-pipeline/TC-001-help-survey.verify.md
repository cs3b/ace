# Goal 1 — Public Surface Survey Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Mapping file exists** — `results/tc/01/public-surface-map.md` exists.
2. **Substantive content** — The file contains more than 5 lines of non-empty text.
3. **Mentions key flags** — The content references at least two of: --fix, --no-report, --validators, --doctor.
4. **Source mapping present** — The content explicitly maps later goals to either `--help` output or sections in `ace-lint/docs/usage.md`.

## Verdict

- **PASS**: All expectations met. Mapping file exists with substantive public-surface references.
- **FAIL**: Mapping file missing, empty, boilerplate-only, or lacks source mapping.

Report: `PASS` or `FAIL` with evidence (quote relevant lines or note their absence).
