# Goal 2 — Bundle Context Processing Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
4. **Primary captures exist** — `bundle.stdout`, `bundle.stderr`, and `bundle.exit` exist in `results/tc/02/`.
5. **Zero exit code** — `bundle.exit` is `0` (bundle mode processing succeeded).
6. **Prompt source recorded** — `bundle-prompt-source.md` exists and includes `BUNDLE_CONTEXT_CHECKPOINT`.
7. **Context-expanded output captured** — `bundle-output.md` exists, is non-empty, and includes:
   - `BUNDLE_CONTEXT_CHECKPOINT` (original prompt evidence), and
   - bundled output content from `ace-bundle` that proves context expansion occurred (for example structured `FILE|`, `SEC|`, or `FACT|` sections).
8. **Archive file created** — `bundle-archive-list.txt` shows at least one archive file entry.
9. **Symlink updated** — `bundle-previous-link.txt` shows `_previous.md` targeting an archive file.

## Verdict

- **PASS**: Bundle-mode process succeeded, prompt+bundle contract evidence is present, and archive lifecycle artifacts are valid.
- **FAIL**: Missing captures, non-zero exit, missing prompt marker, missing bundle contract evidence, or missing archive/symlink evidence.

Report: `PASS` or `FAIL` with evidence (cite filenames and relevant content snippets).
