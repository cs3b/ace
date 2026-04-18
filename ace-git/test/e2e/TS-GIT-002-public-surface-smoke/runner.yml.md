---
description: "E2E runner input for ace-git public-surface smoke"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-help.runner.md
    - ./TC-002-range-routing.runner.md
---

# E2E Test Runner: ace-git Public-Surface Smoke

Tool under test: ace-git
Required tools: ace-git, git
Workspace root: (current directory)

Execute each goal in order.

## Public surface references

- `ace-git/docs/usage.md`
- `ace-git --help`
- `ace-git HEAD~5..HEAD` (range shorthand routes to `diff`)

## Rules

- Setup ownership belongs to `scenario.yml`; do not re-implement setup in TC runners.
- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Save all artifacts to `results/tc/{NN}/` directories.
- Do not assign PASS/FAIL verdicts in runner output.
- Do not fabricate output; all evidence must come from real command execution.

## Artifact conventions

- Save stdout to `{name}.stdout`, stderr to `{name}.stderr`, and exit code to `{name}.exit`.
- The `.exit` file must contain only a numeric exit code.
