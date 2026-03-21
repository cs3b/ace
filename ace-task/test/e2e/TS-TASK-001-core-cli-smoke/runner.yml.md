---
description: "E2E runner input for ace-task core CLI smoke goals"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-help-survey.runner.md
    - ./TC-002-create-show-list.runner.md
    - ./TC-003-update-and-archive.runner.md
    - ./TC-004-doctor-health.runner.md
---

# E2E Test Runner: ace-task Core CLI Smoke

Tool under test: ace-task
Required tools: ace-task, git
Workspace root: (current directory)

Execute each goal sequentially.

## Rules

- Setup ownership belongs to `scenario.yml`; do not re-implement setup in TC runners
- Execute each goal in order (1 through 4)
- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`)
- Save all artifacts to results/tc/{NN}/ directories as specified
- Do not assign PASS/FAIL verdicts in runner output
- Do not fabricate output; all artifacts must come from real command execution
- If a goal fails, capture failure artifacts and continue to the next goal

## Artifact conventions

When a goal requires capturing command output:
- Save stdout to `{name}.stdout`, stderr to `{name}.stderr`, exit code to `{name}.exit`
- The `.exit` file contains only the numeric exit code
