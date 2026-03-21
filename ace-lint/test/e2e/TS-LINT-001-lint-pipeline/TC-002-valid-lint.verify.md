# Goal 2 — Valid File Lint Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Artifacts exist** — Files exist in `results/tc/02/` including a report.json copy and exit code.
2. **Zero exit code** — The captured exit code is `0`.
3. **Report structure** — report.json contains top-level keys: `report_metadata`, `results`, `summary`.
4. **Metadata fields** — report_metadata contains `compact_id`, `generated_at`, `ace_lint_version`.
5. **Summary fields** — summary contains `total_files`, `passed`, `total_errors`.
6. **ok.md exists** — An ok.md copy exists with a "Lint: Passed" header and file listing.

## Verdict

- **PASS**: Exit code 0, report.json has correct structure with metadata and summary, ok.md exists with proper format.
- **FAIL**: Non-zero exit, missing report, incomplete structure, or missing ok.md.

Report: `PASS` or `FAIL` with evidence (exit code, key fields found, ok.md header).
