# Goal 5 — Diff Output Path Security

## Goal

Run `ace-git diff --output ../../etc/passwd` and capture evidence that the
command rejects unsafe output paths.

## Workspace

Save artifacts to `results/tc/05/`.

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/05/`.
- Do not write outside the sandbox.
- Capture artifacts as:
  - `diff-output-security.stdout`
  - `diff-output-security.stderr`
  - `diff-output-security.exit`
