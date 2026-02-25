---
description: "E2E runner input for ace-task task lifecycle"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-create-task.runner.md
    - ./TC-002-start-task.runner.md
    - ./TC-003-complete-task.runner.md
    - ./TC-004-list-tasks.runner.md
---

# E2E Test Runner: ace-task Task Lifecycle

Tool under test: ace-task
Required tools: ace-task, ruby, rg
Workspace root: (current directory)

Execute each goal sequentially. Do not skip earlier goals because later goals
rely on IDs and state created in previous steps.

## Rules

- Execute each goal in order (1 through 4)
- Save artifacts to `results/tc/{NN}/`
- Use real command execution only; do not fabricate output
- If a goal fails, capture evidence and continue
- End with a short summary of produced artifacts per goal
