---
description: "E2E runner input for ace-overseer status and ops tests"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-006-status-watch-refresh.runner.md
    - ./TC-007-work-on-multi-task-bundle.runner.md
---

# E2E Test Runner: ace-overseer status and operations

Tool under test: ace-overseer
Required tools: ace-overseer, ace-git-worktree, ace-tmux, ace-assign, ace-task, git, tmux
Workspace root: (current directory)

Execute each goal sequentially.

## Rules

- Setup ownership belongs to `scenario.yml` and fixtures; do not re-implement setup in TC runners
- Execute each goal in order
- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`)
- Save all artifacts to results/tc/{NN}/ directories as specified
- Do not assign PASS/FAIL verdicts in runner output
- Define `SANDBOX_ROOT="$(pwd)"` once at start
- Use `ACE_TMUX_SESSION` for explicit tmux queries
- Do not fabricate output -- all artifacts must come from real tool execution
- If a goal fails, note the failure and continue to the next goal

## Artifact conventions

When a goal requires capturing command output:

- Save stdout to `{name}.stdout`, stderr to `{name}.stderr`, exit code to `{name}.exit`
- The `.exit` file contains only the numeric exit code (e.g., `0` or `1`)
