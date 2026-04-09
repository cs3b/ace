# Goal 4 — Bundle Context Processing Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
4. **Primary captures exist** — `bundle.stdout`, `bundle.stderr`, and `bundle.exit` exist in `results/tc/04/`.
5. **Zero exit code** — `bundle.exit` is `0` (bundle mode processing succeeded).
6. **Context-expanded output captured** — `bundle-output.md` exists, is non-empty, and contains evidence
   of processed prompt output (for example, original prompt section and/or injected context section).
7. **Archive file created** — `bundle-archive-list.txt` shows at least one archive file entry.
8. **Symlink updated** — `bundle-previous-link.txt` shows `_previous.md` targeting an archive file.

## Verdict

- **PASS**: Bundle-mode process succeeded, output evidence is present, and archive lifecycle artifacts are valid.
- **FAIL**: Missing captures, non-zero exit, missing output evidence, or missing archive/symlink evidence.

Report: `PASS` or `FAIL` with evidence (cite filenames and relevant content snippets).
