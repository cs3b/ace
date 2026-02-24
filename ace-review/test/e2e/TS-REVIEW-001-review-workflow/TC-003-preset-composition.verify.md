# Goal 3 — Preset Composition Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **Both capture sets exist** — results/tc/03/ contains stdout/exit for both level_3 and code-pr tests.
2. **Both exit codes zero** — Both dry-runs succeeded.
3. **Inheritance resolved** — Output shows the presets loaded with their full inheritance chains resolved.

## Verdict

- **PASS**: Both multi-level presets resolve successfully via dry-run.
- **FAIL**: Either dry-run fails or inheritance chain not resolved.

Report: `PASS` or `FAIL` with evidence (exit codes, output showing resolution).
