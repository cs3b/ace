# Goal 2 — Encode Today Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Token file exists** — At least one token-like artifact exists in `results/tc/02/`.
2. **Valid token format** — At least one filename in the directory consists of lowercase alphanumeric characters only (base36 charset: `[0-9a-z]`).
3. **Reasonable length** — At least one token-like filename is 2–8 characters long, consistent with ace-b36ts token format.
4. **Ignore auxiliary captures** — Additional `.txt`/`.md` capture files are allowed and should not fail the goal by themselves.

## Verdict

- **PASS**: A valid base36 token artifact exists (2–8 chars, `[0-9a-z]`), regardless of auxiliary capture files.
- **FAIL**: No valid token artifact exists, token contains invalid characters, or token length is outside expected range.

Report: `PASS` or `FAIL` with evidence (the filename found, or the absence/violation).
