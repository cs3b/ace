# Goal 5 — Batch Mixed Results Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Batch artifacts exist** — results/tc/05/ contains report.json copy and all three markdown files.
2. **Correct categorization** — report.json shows: valid.rb in results.passed, fixable file in results.fixed, syntax_error.rb in results.failed.
3. **All markdown files** — ok.md, fixed.md, and pending.md all exist with correct headers.
4. **No-report suppression** — The `--no-report` test shows exit code `0`, no `Reports:` line in output, and no new lint cache entries created for that run. Use `cache.before`, `cache.after`, and `cache.diff`; an empty `cache.diff` is valid proof even if `.ace-local/lint` already existed before the test.

## Verdict

- **PASS**: Batch correctly categorizes all three files, all markdown files generated, and --no-report suppresses output.
- **FAIL**: Wrong categorization, missing markdown files, or --no-report still generates output.

Report: `PASS` or `FAIL` with evidence (categorization from report.json, markdown file headers, no-report evidence).
