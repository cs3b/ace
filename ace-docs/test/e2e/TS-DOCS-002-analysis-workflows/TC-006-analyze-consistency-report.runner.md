# Goal 6 — Analyze Consistency Report

## Goal

Run `ace-docs analyze-consistency` and capture evidence that the command reports
a concrete analysis/report outcome path.

## Workspace

Save artifacts to `results/tc/06/`.

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/06/`.
- Do not write outside the sandbox.
- Capture command artifacts as:
  - `results/tc/06/analyze-consistency.stdout`
  - `results/tc/06/analyze-consistency.stderr`
  - `results/tc/06/analyze-consistency.exit`

## Required command sequence

Run and capture:

```bash
ace-docs analyze-consistency
```
