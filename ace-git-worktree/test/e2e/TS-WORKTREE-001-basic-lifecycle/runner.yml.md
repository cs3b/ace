---
description: "E2E runner input for ace-git-worktree basic lifecycle goal-based tests"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-help-survey.runner.md
    - ./TC-002-list-and-create.runner.md
    - ./TC-003-switch-and-formats.runner.md
    - ./TC-004-dry-run-ops.runner.md
    - ./TC-005-remove-worktree.runner.md
    - ./TC-006-prune-orphaned.runner.md
---

# E2E Test Runner: ace-git-worktree (Basic Lifecycle)

Tool under test: ace-git-worktree
Required tools: ace-git-worktree, git
Workspace root: (current directory)

Execute each goal sequentially. Goal 1 is discovery — all later goals
build on what you learn there. Do not re-run --help after Goal 1.

## Rules

- Setup ownership belongs to `scenario.yml` and fixtures; do not re-implement setup in TC runners
- Execute each goal in order (1 through 6)
- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`)
- Save all artifacts to results/tc/{NN}/ directories as specified
- Do not assign PASS/FAIL verdicts in runner output
- For system-operation goals (create/remove/prune), capture final system-state evidence with real commands (git metadata + filesystem), not narrative-only notes
- Do not fabricate output — all artifacts must come from real tool execution
- If a goal fails, note the failure and continue to the next goal
- After all goals, output a brief summary of what you produced for each goal

## Artifact conventions

When a goal requires capturing command output:
- Save stdout to `{name}.stdout`, stderr to `{name}.stderr`, exit code to `{name}.exit`
- The `.exit` file contains only the numeric exit code (e.g., `0` or `1`)
- Summary or analysis files (.md) are optional extras — the raw captures are the primary artifacts
