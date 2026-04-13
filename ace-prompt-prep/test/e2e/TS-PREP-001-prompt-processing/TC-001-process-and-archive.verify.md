# Goal 1 — Process and Archive Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
4. **Primary captures exist** — `process.stdout`, `process.stderr`, and `process.exit` exist in `results/tc/01/`.
5. **Zero exit code** — `process.exit` is `0` (processing succeeded).
6. **Archive file created** — `archive-list.txt` shows at least one archive file with Base36-style naming.
7. **Symlink exists** — `previous-link.txt` shows `_previous.md` targeting an archive file.
8. **Content preserved** — `content-diff.txt` (or equivalent) demonstrates archived content matches expected source content.

## Verdict

- **PASS**: Processing succeeded, archive file exists with Base36 ID naming, symlink points to archive, and content is preserved.
- **FAIL**: Non-zero exit code, missing archive file, invalid naming, broken symlink, or content mismatch.

Report: `PASS` or `FAIL` with evidence (cite filenames, archive name, symlink target, and comparison result).
