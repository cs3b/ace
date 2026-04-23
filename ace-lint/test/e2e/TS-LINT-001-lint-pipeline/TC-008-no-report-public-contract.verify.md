# Goal 8 — No-Report Public Contract Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Artifacts exist** — `results/tc/08/` contains capture files for command output and exit status.
2. **Command contract is explicit** — `results/tc/08/command.txt` exists and includes `ace-lint valid.rb --no-report`.
3. **Successful execution** — The captured exit code is `0`.
4. **No report emission** — `results/tc/08/artifact-check.txt` confirms `Reports:` is absent from `lint.stdout`.
5. **No copied report artifacts** — `results/tc/08/artifact-check.txt` confirms there are no copied `report.json`, `ok.md`, `fixed.md`, or `pending.md` files in `results/tc/08/`.

## Verdict

- **PASS**: Exit code is 0 and evidence confirms `--no-report` suppressed report output/artifacts.
- **FAIL**: Non-zero exit or evidence shows report output/artifacts were produced.

Report: `PASS` or `FAIL` with evidence from `command.txt`, `artifact-check.txt`, and the lint captures.
