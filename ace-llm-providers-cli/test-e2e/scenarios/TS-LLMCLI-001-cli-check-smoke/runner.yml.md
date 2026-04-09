---
description: "E2E runner input for ace-llm-providers-cli-check smoke"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-help-surface.runner.md
    - ./TC-002-no-tools.runner.md
    - ./TC-003-stubbed-tools.runner.md
---

# E2E Test Runner: ace-llm-providers-cli-check smoke

Tool under test: ace-llm-providers-cli-check
Required tools: ruby
Workspace root: (current directory)

Execute each goal in order.

## Rules

- Setup ownership belongs to `scenario.yml` and fixtures; do not re-implement setup in TC runners
- Execute each goal in order (1 through 3)
- Save all artifacts to `results/tc/{NN}/` directories as specified
- Do not assign PASS/FAIL verdicts in runner output
- Do not fabricate output; all artifacts must come from real command execution
- For each command capture stdout, stderr, and exit code
- If a goal fails, continue to the next goal

## Artifact conventions

- Save stdout to `{name}.stdout`, stderr to `{name}.stderr`, exit code to `{name}.exit`
- The `.exit` file must contain only a numeric exit code
- Keep optional summaries in `.md` files, but raw command captures are the primary evidence
