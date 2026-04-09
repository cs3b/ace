# Goal 4 — Error Handling Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Capture set exists** — `results/tc/04/` contains stdout/stderr/exit captures for the missing resource attempt.
2. **Non-zero exit code** — The exit code is non-zero (the tool correctly signals failure).
3. **Informative error message** — Stderr contains a human-readable error message (e.g., mentioning "not found", the missing resource name, or suggesting alternatives).
4. **Error identifies target** — Stderr references the attempted missing resource token (for example `nonexistent-resource`), not only a generic failure.
5. **No stack trace** — Stderr does not contain a Ruby stack trace (no lines like `from /path/to/file.rb:NN:in`).

## Verdict

- **PASS**: Non-zero exit code, message identifies the missing resource, and no stack trace is present.
- **FAIL**: Zero exit code, generic/missing message, missing resource identifier, or stack trace in output.

Report: `PASS` or `FAIL` with evidence (exit code, error message snippet, presence/absence of stack trace).
