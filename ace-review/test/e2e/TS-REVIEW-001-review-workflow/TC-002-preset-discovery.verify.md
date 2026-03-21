# Goal 2 — Preset Discovery Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Capture set exists** — results/tc/02/ contains stdout/exit for preset listing.
2. **Zero exit code** — Listing succeeded.
3. **Multiple presets found** — Output lists at least 4 preset names (e.g., code, code-pr, level_1, single).

## Verdict

- **PASS**: Preset listing succeeds and shows multiple presets from both config and filesystem sources.
- **FAIL**: Listing fails, or fewer than expected presets shown.

Report: `PASS` or `FAIL` with evidence (exit code, preset names found).
