# Goal 1 — Help Survey Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **File exists** — At least one file exists in `results/tc/01/`.
2. **Substantive content** — The file contains more than 5 lines of non-empty text.
3. **Mentions key concepts** — The content references at least two of: presets, subjects, models, dry-run.
4. **Observations present** — The content includes at least one observation about the tool's interface.

## Verdict

- **PASS**: File exists with substantive observations about ace-review's interface.
- **FAIL**: File missing, empty, or lacks mention of key concepts.

Report: `PASS` or `FAIL` with evidence.
