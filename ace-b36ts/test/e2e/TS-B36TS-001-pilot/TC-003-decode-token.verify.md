# Goal 3 — Decode Token Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **File exists** — A file named `i50jj3` exists in `results/tc/03/`.
2. **Content is a valid date/timestamp** — The file content contains a recognizable date or timestamp (e.g., ISO 8601 format, or a human-readable date string). It must not be empty or contain only whitespace.
3. **Content is plausible** — The decoded date should be a real, reasonable date (not epoch zero, not far-future).
4. **Error diagnostics** — If the file is missing or empty, check for `results/tc/03/i50jj3.stderr` and `results/tc/03/i50jj3.exit`. Report the error message and exit code as evidence for why the decode failed.

## Verdict

- **PASS**: File `results/tc/03/i50jj3` exists with non-empty content containing a valid, plausible date or timestamp.
- **FAIL**: File missing, wrong name, empty content, or content is not a recognizable date/timestamp. If `.stderr` and `.exit` files exist, cite the error message and exit code as supporting evidence.

Report: `PASS` or `FAIL` with evidence (the file content found, or the absence/violation).
