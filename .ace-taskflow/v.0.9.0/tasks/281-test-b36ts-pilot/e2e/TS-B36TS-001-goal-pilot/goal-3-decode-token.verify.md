# Goal 3 — Decode Token Verification

## Injected Context

The verifier receives the `goal/` directory tree and access to the sandbox path.

## Expectations

1. **File exists** — A file named `70000` exists in `goal/3/`.
2. **Content is a valid date/timestamp** — The file content contains a recognizable date or timestamp (e.g., ISO 8601 format, or a human-readable date string). It must not be empty or contain only whitespace.
3. **Content is plausible** — The decoded date should be a real, reasonable date (not epoch zero, not far-future).

## Verdict

- **PASS**: File `goal/3/70000` exists with non-empty content containing a valid, plausible date or timestamp.
- **FAIL**: File missing, wrong name, empty content, or content is not a recognizable date/timestamp.

Report: `PASS` or `FAIL` with evidence (the file content found, or the absence/violation).
