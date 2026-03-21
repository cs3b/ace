# Goal 7 — Multi-Model and Reviewers Format Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Both capture sets exist** — results/tc/07/ contains captures for multi and reviewers tests.
2. **Both exit codes zero** — Both review executions succeeded.
3. **Session directories created** — Both tests created session directories with review output files.
4. **Review files exist** — At least one review output file exists per execution.

## Verdict

- **PASS**: Both multi-model and reviewers-format presets execute successfully with output files created.
- **FAIL**: Either execution fails or no output files generated.

Report: `PASS` or `FAIL` with evidence (exit codes, session directories, file counts).
