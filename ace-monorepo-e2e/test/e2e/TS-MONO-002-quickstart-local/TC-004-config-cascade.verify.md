# Goal 4 — Configuration Cascade Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Config override created** — `.ace/git/commit.yml` exists in the sandbox with `max_subject_length` and `body_wrap` settings.
2. **Prompt override created** — `.ace-handbook/prompts/git-commit.system.md` exists in the sandbox.
3. **Override content correct** — `results/tc/04/override-content.txt` contains the YAML settings (`max_subject_length: 72`, `body_wrap: 80`).
4. **Cascade check passes** — `results/tc/04/cascade-check.txt` confirms both override paths exist.

## Verdict

- **PASS**: Both project-level override paths documented in quick-start.md are valid, writable, and contain expected content.
- **FAIL**: Override files missing, wrong path, or content doesn't match documented values.

Report: `PASS` or `FAIL` with evidence.
