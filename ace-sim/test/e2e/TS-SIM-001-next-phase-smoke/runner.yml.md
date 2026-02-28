---
description: "E2E runner input for ace-sim preset-chain smoke"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-help-survey.runner.md
    - ./TC-002-preset-contract.runner.md
    - ./TC-003-run-chain-artifacts.runner.md
    - ./TC-004-full-chain-synthesis.runner.md
---

# E2E Test Runner: ace-sim Preset-Chain Smoke

Tool under test: ace-sim
Required tools: ace-sim, ace-llm
Workspace root: (current directory)

Execute each goal sequentially. Goal 1 is discovery.

## Rules

- Setup ownership belongs to `scenario.yml` and fixtures; do not re-implement setup in TC runners
- Execute each goal in order (1 through 4)
- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`)
- Save all artifacts to results/tc/{NN}/ directories as specified
- Do not assign PASS/FAIL verdicts in runner output
- Do not fabricate output — all artifacts must come from real tool execution
- If a goal fails, note the failure and continue to the next goal
- After all goals, output a brief summary of what you produced for each goal

## Artifact conventions

When a goal requires capturing command output:
- Save stdout to `{name}.stdout`, stderr to `{name}.stderr`, exit code to `{name}.exit`
- The `.exit` file contains only the numeric exit code (e.g., `0` or `1`)
