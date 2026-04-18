---
description: "E2E runner input for ace-sim dry-run public contract"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-dry-run-public-contract.runner.md
---

# E2E Test Runner: ace-sim Dry-Run Public Contract

Tool under test: ace-sim
Required tools: ace-sim
Workspace root: (current directory)

Execute each goal sequentially.

## Rules

- Setup ownership belongs to `scenario.yml` and fixtures; do not re-implement setup in TC runners
- Execute each goal in order (1 through 1)
- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`)
- Save all artifacts to results/tc/{NN}/ directories as specified
- Do not assign PASS/FAIL verdicts in runner output
- Do not fabricate output — all artifacts must come from real tool execution

## Artifact conventions

When a goal requires capturing command output:
- Save stdout to `{name}.stdout`, stderr to `{name}.stderr`, exit code to `{name}.exit`
- The `.exit` file contains only the numeric exit code (e.g., `0` or `1`)
