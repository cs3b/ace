---
description: "E2E runner input for agy provider smoke"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-success.runner.md
    - ./TC-002-resume.runner.md
    - ./TC-003-failure.runner.md
---

# E2E Test Runner: agy provider smoke

Tool under test: ace-llm
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
