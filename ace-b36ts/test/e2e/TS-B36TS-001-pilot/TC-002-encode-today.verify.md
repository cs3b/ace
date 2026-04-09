# Goal 2 — Encode Today Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Command succeeded** — `encode-today.exit` should indicate success.
2. **Token captured in stdout** — `encode-today.stdout` should contain a non-empty token emitted by the tool.
3. **Valid token format** — The token should consist of lowercase alphanumeric characters only (base36 charset: `[0-9a-z]`).
4. **Reasonable length** — The token should be 2–8 characters long, consistent with ace-b36ts token format.
5. **Ignore auxiliary captures** — Additional support files are allowed and should not fail the goal by themselves.

## Verdict

- **PASS**: The command succeeds and stdout contains a valid base36 token (2–8 chars, `[0-9a-z]`).
- **FAIL**: The command fails, stdout does not contain a token, token contains invalid characters, or token length is outside expected range.

Report: `PASS` or `FAIL` with evidence (the token found in stdout, or the absence/violation).
