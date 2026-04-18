---
description: "E2E runner input for ace-tmux outside-tmux window targeting"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-005-window-outside-tmux.runner.md
---

# E2E Test Runner: ace-tmux Outside-Tmux Window Targeting

Tool under test: ace-tmux
Required tools: ace-tmux
Workspace root: (current directory)

Run Goal 5 to validate `ace-tmux window --session` behavior from outside tmux.

## Rules

- Setup ownership belongs to `scenario.yml` and fixtures; do not re-implement setup in TC runners
- Use only declared scenario tools
- Save all artifacts to `results/tc/05/`
- Do not assign PASS/FAIL verdicts in runner output
- Do not fabricate output; all artifacts must come from real command execution
- For each command capture stdout, stderr, and exit code

## Artifact conventions

- Save stdout to `{name}.stdout`, stderr to `{name}.stderr`, exit code to `{name}.exit`
- The `.exit` file must contain only a numeric exit code
- Keep optional summaries in `.md` files, but real tool output and runner observations are the primary evidence
