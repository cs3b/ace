# Goal 3 — Fix Mode Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Artifacts exist** — Files exist in `results/tc/03/` including diff evidence and exit code.
2. **File was modified** — The diff or comparison shows the fixable file was changed by --fix (not identical to the original).
3. **Fixed count > 0** — The summary.fixed value from report.json is greater than 0.
4. **fixed.md exists** — A fixed.md copy exists with a "Lint: Auto-Fixed Files" header mentioning the fixed file.

## Verdict

- **PASS**: File was modified, fixed count > 0, and fixed.md exists with proper format.
- **FAIL**: File unchanged, zero fixed count, or missing fixed.md.

Report: `PASS` or `FAIL` with evidence (diff snippet, fixed count, fixed.md header).
