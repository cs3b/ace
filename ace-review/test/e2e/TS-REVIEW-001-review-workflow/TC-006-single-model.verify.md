# Goal 6 — Single Model Execution Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Artifacts exist** — results/tc/06/ contains execution captures and session listing.
2. **Zero exit code** — Review execution succeeded.
3. **Session directory created** — Session listing shows a directory was created with review output.
4. **Meaningful content** — The review output file contains more than 3 lines of substantive content (not just boilerplate).

## Verdict

- **PASS**: Review executed successfully, session created, output contains meaningful review content.
- **FAIL**: Execution failed, no session, or empty/boilerplate output.

Report: `PASS` or `FAIL` with evidence (exit code, session directory, content snippet).
