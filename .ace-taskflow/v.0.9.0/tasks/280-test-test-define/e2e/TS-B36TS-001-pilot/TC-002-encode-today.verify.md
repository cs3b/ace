# Goal 2 — Encode Today Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **File exists** — Exactly one file exists in `results/tc/02/`.
2. **Valid token format** — The filename consists of lowercase alphanumeric characters only (base36 charset: `[0-9a-z]`).
3. **Reasonable length** — The filename is 2–8 characters long, consistent with ace-b36ts token format.

## Verdict

- **PASS**: Exactly one file in `results/tc/02/` with a valid base36 filename of reasonable length.
- **FAIL**: No file, multiple files, filename contains invalid characters, or filename length outside expected range.

Report: `PASS` or `FAIL` with evidence (the filename found, or the absence/violation).
