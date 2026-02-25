# Goal 3 — Process and Archive Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Artifacts exist** — Files exist in `results/tc/03/` showing archive evidence.
2. **Zero exit code** — The captured exit code is `0` (processing succeeded).
3. **Archive file created** — Evidence shows at least one file in the archive directory with a Base36 ID filename (lowercase alphanumeric characters, typically 6 characters).
4. **Symlink exists** — Evidence shows `_previous.md` is a symlink pointing to a file in the archive directory.
5. **Content preserved** — Evidence shows the archived content matches or is derived from the original sample prompt (diff shows no unexpected changes, or content comparison confirms match).

## Verdict

- **PASS**: Processing succeeded, archive file exists with Base36 ID naming, symlink points to archive, and content is preserved.
- **FAIL**: Non-zero exit code, missing archive file, invalid naming, broken symlink, or content mismatch.

Report: `PASS` or `FAIL` with evidence (exit code, archive filename, symlink target, content comparison).
