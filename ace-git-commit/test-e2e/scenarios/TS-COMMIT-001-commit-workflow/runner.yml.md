---
description: "E2E runner input for ace-git-commit goal-based tests"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-help-survey.runner.md
    - ./TC-002-basic-commit.runner.md
    - ./TC-003-dry-run-and-paths.runner.md
    - ./TC-004-delete-and-rename.runner.md
    - ./TC-005-auto-split.runner.md
    - ./TC-006-no-split.runner.md
---

# E2E Test Runner: ace-git-commit

Tool under test: ace-git-commit
Required tools: ace-git-commit, git
Workspace root: (current directory)

Execute each goal sequentially. Each goal should be self-contained and must not depend on discoveries from earlier goals.

## Rules

- Setup ownership belongs to `scenario.yml` and fixtures; do not re-implement setup in TC runners
- Execute each goal in order (1 through 6)
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
- Summary or analysis files (.md) are optional extras — the raw captures are the primary artifacts
