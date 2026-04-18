# Goal 6 — Create From Public Path Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. **Create capture set exists** — `results/tc/06/create.stdout`, `.stderr`, and `.exit` are present.
2. **Create command succeeded** — `results/tc/06/create.exit` is `0`.
3. **Created path artifact exists** — `results/tc/06/created.path` exists and contains a file path.
4. **Created file exists on disk** — File at `created.path` exists and is non-empty.
5. **Output is user-usable** — Created file content appears as a valid text template/resource output (not an empty placeholder).

## Verdict

- **PASS**: Public create command succeeds and produces a usable created file.
- **FAIL**: Missing artifacts, failed create, or absent/empty created file.

Report: `PASS` or `FAIL` with evidence (exit code, created path, file checks).
