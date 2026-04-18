# Goal 5 — Batch Integrated Outcomes Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Batch artifacts exist** — results/tc/05/ contains report.json copy and all three markdown files.
2. **Same-run report evidence is grounded** — copied report artifacts come from the emitted report directory for this batch command.
3. **Correct categorization** — valid.rb is shown as passed, syntax_error.rb is shown as failed, and the fixable file is shown as auto-fixed by either `results.fixed` or `fixed.md`.
4. **Markdown outputs match the captured batch run** — `ok.md` and `pending.md` exist with correct headers; `fixed.md` is required only when the same-run batch report emitted a fixed-file section.

## Verdict

- **PASS**: Batch correctly categorizes the three files using one captured report set.
- **FAIL**: Wrong categorization, mixed-run report evidence, or missing required batch artifacts.

Report: `PASS` or `FAIL` with evidence (command/report-dir proof, categorization from report.json, and markdown headers).
