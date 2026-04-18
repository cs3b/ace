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
3. **Same-run report evidence is grounded** — if report artifacts are present, they come from the emitted report directory captured for this command.
4. **Fix signal exists** — same-run report evidence shows the fixable file was auto-fixed, via either:
   - `summary.fixed > 0` in `report.json`, or
   - `fixed.md` with a `Lint: Auto-Fixed Files` header mentioning the fixed file.

## Verdict

- **PASS**: File was modified and same-run report evidence confirms the file was auto-fixed.
- **FAIL**: File unchanged, missing command evidence, or no same-run fix signal.

Report: `PASS` or `FAIL` with evidence (diff snippet, command/report-dir proof, and fix signal).
