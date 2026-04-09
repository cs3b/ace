# Goal 4 - Doctor Health to Failure Transition

## Goal

Run `ace-retro doctor` once on valid state, then intentionally corrupt one retro
file and confirm doctor detects failure in a subsequent run.

## Workspace

Save artifacts to `results/tc/04/`.

Capture:
- `results/tc/04/doctor-healthy.stdout`, `.stderr`, `.exit` from initial `ace-retro doctor`
- `results/tc/04/corrupted-file.path` containing path to the file intentionally corrupted
- `results/tc/04/corrupted-file.md` capturing corrupted content snapshot
- `results/tc/04/doctor-broken.stdout`, `.stderr`, `.exit` from doctor after corruption

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Do not rely on retro files created by earlier goals. Before the first `ace-retro doctor` run in this TC, create a fresh valid retro corpus for this goal inside the sandbox-local `.ace-retros/` tree so the initial doctor check starts from a known-good state.
- The initial `doctor-healthy.*` artifacts must come from that freshly prepared valid state, not inherited scenario state.
- Corruption must remain inside sandbox-local retro files only.
- Corruption must produce invalid frontmatter (error-level), not only a scope warning:
  - Pick one `*.retro.md` file under scenario-local `.ace-retros/`.
  - Persist its path in `results/tc/04/corrupted-file.path`.
  - Overwrite that file with malformed YAML frontmatter (for example `id: [broken` with no valid closing structure).
  - Save the resulting file content in `results/tc/04/corrupted-file.md`.
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/04/`.
