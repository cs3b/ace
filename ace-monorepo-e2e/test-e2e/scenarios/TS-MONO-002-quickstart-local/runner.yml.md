---
description: "E2E runner input for quick-start local validation"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-idea-capture.runner.md
    - ./TC-002-task-create.runner.md
    - ./TC-003-protocol-nav.runner.md
    - ./TC-004-config-cascade.runner.md
---

# E2E Test Runner: Quick-Start Local Validation

Tools under test: ace-idea, ace-task, ace-bundle, ace-nav
Required tools: ace-idea, ace-task, ace-bundle, ace-nav, ace-search
Workspace root: (current directory)

This scenario validates that the locally-executable steps from
`docs/quick-start.md` work as documented. The sandbox has the
quick-start doc available at `quick-start.md` for reference.

Execute each goal sequentially.

## Rules

- Setup ownership belongs to `scenario.yml`; do not re-implement setup in TC runners
- Execute each goal in order (1 through 4)
- Use only declared scenario tools
- Save all artifacts to results/tc/{NN}/ directories as specified
- Do not assign PASS/FAIL verdicts in runner output
- Do not fabricate output — all artifacts must come from real tool execution
- If a goal fails, note the failure and continue to the next goal
- After all goals, output a brief summary of what you produced for each goal

## Artifact conventions

When a goal requires capturing command output:
- Save stdout to `{name}.stdout`, stderr to `{name}.stderr`, exit code to `{name}.exit`
- The `.exit` file contains only the numeric exit code (e.g., `0` or `1`)
