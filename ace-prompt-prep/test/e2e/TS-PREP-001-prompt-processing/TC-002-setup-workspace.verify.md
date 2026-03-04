# Goal 2 — Setup Workspace Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Artifacts exist** — At least one file exists in `results/tc/02/` containing directory listing or setup evidence.
2. **Zero exit code** — The captured exit code is `0` (setup succeeded).
3. **Workspace directory created** — Evidence shows a prompt workspace directory was created (e.g., `.ace-local/prompt-prep/prompts/` or similar path visible in the directory listing).
4. **Template file present** — Evidence shows a template prompt file was created with non-empty content (more than 0 lines).

## Verdict

- **PASS**: Setup exited successfully, workspace directory was created, and a non-empty template file exists.
- **FAIL**: Non-zero exit code, missing workspace directory, or empty/missing template file.

Report: `PASS` or `FAIL` with evidence (exit code, directory paths, template content snippet).
