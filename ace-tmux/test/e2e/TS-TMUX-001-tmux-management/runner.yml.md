---
description: "E2E runner input for ace-tmux management"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-list-presets.runner.md
    - ./TC-002-start-session.runner.md
    - ./TC-003-add-window.runner.md
    - ./TC-004-start-existing-session.runner.md
    - ./TC-005-runtime-list.runner.md
---

# E2E Test Runner: ace-tmux Management

Tool under test: ace-tmux
Required tools: ace-tmux
Workspace root: (current directory)

Run goals sequentially. Goal 1 discovers presets, Goal 2 starts a session, Goal 3 adds a window, Goal 4 exercises
existing-session start behavior, and Goal 5 inspects the live tmux runtime through `ace-tmux list`.

## Rules

- Setup ownership belongs to `scenario.yml` and fixtures; do not re-implement setup in TC runners
- Execute each goal in order (1 through 5)
- Use only declared scenario tools
- Save all artifacts to results/tc/{NN}/ directories as specified
- Do not assign PASS/FAIL verdicts in runner output
- Do not fabricate output; all artifacts must come from real command execution
- For each command capture stdout, stderr, and exit code
- If a goal fails, continue to the next goal

## Artifact conventions

- Save stdout to `{name}.stdout`, stderr to `{name}.stderr`, exit code to `{name}.exit`
- The `.exit` file must contain only a numeric exit code
- Keep optional summaries in `.md` files, but real tool output and runner observations are the primary evidence
