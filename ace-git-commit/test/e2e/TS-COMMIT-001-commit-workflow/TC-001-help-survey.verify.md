# Goal 1 — Help Survey Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
- **File exists** — At least one file exists in `results/tc/01/`.
- **Substantive content** — The file contains more than 5 lines of non-empty text.
- **Mentions key flags** — The content references at least two of: -m, --dry-run, --no-split, path arguments.
- **Observations present** — The content includes at least one observation about the tool's interface.

## Verdict

- **PASS**: File exists with substantive observations about ace-git-commit's interface.
- **FAIL**: File missing, empty, or lacks mention of key flags.

Report: `PASS` or `FAIL` with evidence.
