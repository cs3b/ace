---
description: "E2E runner input for ace-test-suite behavior"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-run-full-suite.runner.md
    - ./TC-002-verify-failure-propagation.runner.md
---

# E2E Test Runner: ace-test-suite Behavior

Tool under test: ace-test-suite
Required tools: ace-test-suite, ace-test
Workspace root: (current directory)

Goal 1 validates normal suite execution; Goal 2 intentionally introduces a
failing test file in sandbox and verifies non-zero propagation.

## Rules

- Setup ownership belongs to `scenario.yml` and fixtures; do not re-implement setup in TC runners
- Execute each goal in order (1 through 2)
- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`)
- Save all artifacts to results/tc/{NN}/ directories as specified
- Do not assign PASS/FAIL verdicts in runner output
- Do not fabricate output; all artifacts must come from real command execution
- For each command capture stdout, stderr, and exit code
- If a goal fails, continue to the next goal

## Artifact conventions

- Save stdout to `{name}.stdout`, stderr to `{name}.stderr`, exit code to `{name}.exit`
- The `.exit` file must contain only a numeric exit code
- Keep optional summaries in `.md` files, but raw command captures are the primary evidence
