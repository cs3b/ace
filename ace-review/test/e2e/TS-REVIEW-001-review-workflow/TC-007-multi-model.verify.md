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
3. **Session directories created** — `multi-session-listing.txt` and `reviewers-session-listing.txt` show that both tests created session directories with review output files.
4. **Prepared execution evidence exists** — Each run either created review output files or prepared a session with prompt files and an explicit `To execute with LLM:` handoff.
5. **Support captures optional** — Copied review outputs may be present, but their absence alone is not a failure when execution output and session listings already prove the runs.

## Verdict

- **PASS**: Both multi-model and reviewers-format presets execute successfully and create usable execution/preparation sessions.
- **FAIL**: Either execution fails or no usable session/output is generated.

Report: `PASS` or `FAIL` with evidence (exit codes, session directories, file counts).
