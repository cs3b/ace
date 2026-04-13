# Goal 5 — Diff Output Path Security Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/05/` contains:
   - `diff-output-security.stdout`
   - `diff-output-security.stderr`
   - `diff-output-security.exit`
2. Exit code is non-zero.
3. Output contains explicit path validation rejection evidence (for example
   `path traversal not allowed` or `must be within working directory or temp directory`).

## Verdict

- **PASS**: Unsafe output path is rejected with explicit evidence.
- **FAIL**: Command succeeds unexpectedly or rejection evidence is missing.
