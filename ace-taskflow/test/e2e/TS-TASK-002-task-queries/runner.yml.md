---
description: "E2E runner input for ace-task query workflows"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-show-task-details.runner.md
    - ./TC-002-filter-by-status.runner.md
    - ./TC-003-taskflow-status.runner.md
---

# E2E Test Runner: ace-task Query Workflows

Tool under test: ace-task, ace-taskflow
Required tools: ace-task, ace-taskflow
Workspace root: (current directory)

Execute each goal in order.

## Rules

- Execute each goal in order (1 through 3)
- Use only ace-task/ace-taskflow and standard shell utilities
- Save all artifacts to results/tc/{NN}/ directories as specified
- Do not fabricate output; all artifacts must come from real command execution
- For each command capture stdout, stderr, and exit code
- If a goal fails, continue to the next goal

## Artifact conventions

- Save stdout to `{name}.stdout`, stderr to `{name}.stderr`, exit code to `{name}.exit`
- The `.exit` file must contain only a numeric exit code
- Keep optional summaries in `.md` files, but raw command captures are the primary evidence
