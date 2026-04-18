# Goal 3 — Setup Initializes Workspace Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
4. **Primary captures exist** — `setup.stdout`, `setup.stderr`, and `setup.exit` exist in `results/tc/03/`.
5. **Zero exit code** — `setup.exit` is `0`.
6. **Workspace initialized** — `workspace-tree.txt` shows `.ace-local/prompt-prep/prompts` with `the-prompt.md`.
7. **Primary prompt file present** — `workspace-main-file.txt` exists and is non-empty.

## Verdict

- **PASS**: Setup command succeeds and workspace artifacts confirm documented initialization behavior.
- **FAIL**: Non-zero exit code, missing captures, or missing/empty workspace artifacts.

Report: `PASS` or `FAIL` with evidence (cite filenames and relevant content snippets).
