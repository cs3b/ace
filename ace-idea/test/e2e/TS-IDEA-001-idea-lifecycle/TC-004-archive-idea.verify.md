# Goal 4 — Archive Idea Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. `.ace-ideas/_archive` exists and contains the moved idea as a `.idea.s.md` file.
2. `ace-idea update --move-to archive` exit code is `0` and `stdout` includes `Idea updated:` and `_archive`.
3. `ace-idea list --in archive` exit code is `0` and output includes the moved idea.

## Verdict

- **PASS**: Idea is archived on disk and archive-filtered listing shows it.
- **FAIL**: Archive path not created, update command fails, or archived listing omits the idea.
