---
description: "E2E runner input for ace-assign hierarchy and injection goal-based tests"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-injection-renumbering.runner.md
    - ./TC-002-auto-completion.runner.md
    - ./TC-003-hierarchy-errors.runner.md
    - ./TC-004-display-audit.runner.md
    - ./TC-005-fork-subtree.runner.md
---

# E2E Test Runner: ace-assign Hierarchy and Injection

Tool under test: ace-assign
Required tools: ace-assign
Workspace root: (current directory)

Execute each goal sequentially. Each goal tests a distinct aspect of
ace-assign's hierarchical step management.

## Rules

- Setup ownership belongs to `scenario.yml` and fixtures; do not re-implement setup in TC runners
- Execute each goal in order (1 through 5)
- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`)
- Save all artifacts to results/tc/{NN}/ directories as specified
- Do not assign PASS/FAIL verdicts in runner output
- Do not fabricate output — all artifacts must come from real tool execution
- If a goal fails, note the failure and continue to the next goal
- Clean up assignment cache between goals when specified to avoid state bleed
- After all goals, output a brief summary of what you produced for each goal

## Artifact conventions

When a goal requires capturing command output:
- Save stdout to `{name}.stdout`, stderr to `{name}.stderr`, exit code to `{name}.exit`
- The `.exit` file contains only the numeric exit code (e.g., `0` or `1`)
- Summary or analysis files (.md) are optional extras — the raw captures are the primary artifacts
