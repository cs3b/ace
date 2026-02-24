# Goal 1 — Help Survey Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **File exists** — At least one file exists in `results/tc/01/`.
2. **Substantive content** — The file contains more than 5 lines of non-empty text.
3. **Mentions key concepts** — The content references presets, output modes, or bundling behavior.
4. **Observations present** — The content includes at least one observation about the tool's interface.

## Verdict

- **PASS**: All expectations met. File exists with substantive observations about ace-bundle's interface.
- **FAIL**: File missing, empty, boilerplate-only, or lacks mention of key concepts.

Report: `PASS` or `FAIL` with evidence.
