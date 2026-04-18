# Goal 5 — Analyze Document Drift

## Goal

Run `ace-docs analyze` for a managed document and capture command evidence for the
single-document analysis workflow.

## Workspace

Save artifacts to `results/tc/05/`.

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/05/`.
- Do not write outside the sandbox.
- Capture analyze command artifacts as:
  - `results/tc/05/analyze.stdout`
  - `results/tc/05/analyze.stderr`
  - `results/tc/05/analyze.exit`

## Required command sequence

Run and capture:

```bash
ace-docs analyze docs/guide.md --since 2025-01-01
```
