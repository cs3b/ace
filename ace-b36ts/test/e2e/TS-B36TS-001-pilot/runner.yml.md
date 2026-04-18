---
description: "E2E runner input for ace-b36ts public-surface goal workflows"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-notes-reorganization.runner.md
    - ./TC-002-decode-roundtrip-from-real-token.runner.md
    - ./TC-003-split-and-json-output-for-archive-pathing.runner.md
---

# E2E Test Runner: ace-b36ts Public-Surface Goal Workflow

Tool under test: ace-b36ts
Workspace root: (current directory)

Execute each goal sequentially.

## Public surface references

- `ace-b36ts/docs/usage.md`
- `ace-b36ts --help`

## Rules

- Setup ownership belongs to `scenario.yml`; do not re-implement setup in TC runners.
- Execute goals in order (1 through 3).
- Use only declared tools and public CLI entry points.
- Save artifacts only under `results/tc/{NN}/`.
- Do not assign PASS/FAIL verdicts in runner output.
- Do not fabricate outputs; all evidence must come from real command execution.

## Artifact conventions

When a goal requires capturing command output:

- Save stdout to `{name}.stdout`, stderr to `{name}.stderr`, and exit code to `{name}.exit`.
- The `.exit` file contains only the numeric exit code.
