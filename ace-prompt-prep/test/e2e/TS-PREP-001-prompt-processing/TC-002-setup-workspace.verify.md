# Goal 2 — Setup Workspace Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
4. **Primary captures exist** — `setup.stdout`, `setup.stderr`, and `setup.exit` exist in `results/tc/02/`.
5. **Zero exit code** — `setup.exit` is `0` (setup succeeded).
6. **Workspace directory created** — `workspace-tree.txt` shows prompt workspace path (e.g., `.ace-local/prompt-prep/prompts/`).
7. **Template file present** — `template.md` exists and is non-empty.

## Verdict

- **PASS**: Setup exited successfully, workspace directory was created, and a non-empty template file exists.
- **FAIL**: Non-zero exit code, missing workspace directory, or empty/missing template file.

Report: `PASS` or `FAIL` with evidence (cite filenames, exit code value, and template snippet).
