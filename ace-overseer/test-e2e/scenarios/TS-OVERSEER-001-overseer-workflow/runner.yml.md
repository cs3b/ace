---
description: "E2E runner input for ace-overseer goal-based tests"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-help-survey.runner.md
    - ./TC-002-work-on.runner.md
    - ./TC-003-idempotent-rerun.runner.md
    - ./TC-004-preset-override.runner.md
    - ./TC-005-prune-workflow.runner.md
---

# E2E Test Runner: ace-overseer

Tool under test: ace-overseer
Required tools: ace-overseer, ace-git-worktree, ace-tmux, ace-assign, ace-task, git, tmux
Workspace root: (current directory)

Execute each goal sequentially. Goal 1 is discovery — all later goals
build on what you learn there. Do not re-run --help after Goal 1.

## Rules

- Setup ownership belongs to `scenario.yml` and fixtures; do not re-implement setup in TC runners
- Execute each goal in order (1 through 5)
- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`)
- Save all artifacts to results/tc/{NN}/ directories as specified
- Do not assign PASS/FAIL verdicts in runner output
- Define `SANDBOX_ROOT="$(pwd)"` once at start; if you must `cd` into a worktree, return outputs to `${SANDBOX_ROOT}/results/...`
- Use `ACE_TMUX_SESSION` for all explicit tmux queries (for example `tmux list-windows -t "$ACE_TMUX_SESSION"`); do not rely on implicit/default tmux session.
- Do not fabricate output — all artifacts must come from real tool execution
- Do not run remediation or fallback commands outside the explicit goal contracts
- If a goal fails, note the failure and continue to the next goal
- After all goals, output a brief summary of what you produced for each goal

## Artifact conventions

When a goal requires capturing command output:
- Save stdout to `{name}.stdout`, stderr to `{name}.stderr`, exit code to `{name}.exit`
- The `.exit` file contains only the numeric exit code (e.g., `0` or `1`)
